//
//  RetentionPushStepsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A retention push against a simulated App Store Connect: the image's
/// placement group and asset category from Apple's reference data, a
/// local image uploaded to the Asset Library once, an offer's equalized
/// prices, a message a retried push made, a refused review submission,
/// and a whole message through `PushController`. Nothing reaches the
/// network.
@MainActor
@Suite("Retention push steps")
struct RetentionPushStepsTests {
    private typealias Fixtures = RetentionTestFixtures

    /// Reference data with a retention placement type, as the API documents
    /// the shape (the real group and category names are untested).
    static let refData = Data("""
    {"data": [{"type": "appAssetLibraryRefData", "id": "1", "attributes": {
      "imageSpecs": [{"specId": "spec-retention", "dimensions": {"minWidth": 3840, "maxWidth": 3840, "minHeight": 160, "maxHeight": 2160},
                      "compatiblePlacementTypes": ["RETENTION_MESSAGE_ASSET"]}],
      "placementTypes": [{"placementTypeId": "RETENTION_MESSAGE_ASSET", "acceptsAssetCategories": ["RETENTION_ASSETS"],
                          "specMappings": [{"placementGroupId": "RETENTION_UNIVERSAL", "specs": ["spec-retention"]}]}]
    }}]}
    """.utf8)

    private static func created(_ type: String, _ id: String) -> Data {
        Data(#"{"data":{"type":"\#(type)","id":"\#(id)"}}"#.utf8)
    }

    private func placement(of request: PushRequest) -> (group: String?, imageID: String?) {
        let data = Fixtures.data(request)
        let image = ((data["relationships"] as? [String: Any])?["image"] as? [String: Any])?["data"] as? [String: Any]
        return ((data["attributes"] as? [String: Any])?["placementGroup"] as? String, image?["id"] as? String)
    }

    // MARK: - Image

    @Test func thePlacementGroupAndCategoryComeFromAppleReferenceData() async throws {
        let push = FakePushTransport(remote: [AssetLibraryRequests.refDataPath: Self.refData])
        let request = RetentionRequests.placeImage(imageID: "asset.lake", pixelWidth: 3840, pixelHeight: 1000)
        let resolved = try await RetentionPushSteps.resolving(request, known: [:], via: push) { _ in }

        #expect(placement(of: resolved.request).group == "RETENTION_UNIVERSAL")
        #expect(placement(of: resolved.request).imageID == "asset.lake")
        #expect(resolved.created.isEmpty)
        #expect(RetentionPlacementGroup.assetCategory(in: Self.refData) == "RETENTION_ASSETS")
    }

    @Test func aSizeAppleDoesntTakeStopsBeforeUploading() async {
        let library = FakeAssetLibrary()
        let transport = RetentionPushTransport(push: FakePushTransport(remote: [AssetLibraryRequests.refDataPath: Self.refData]), library: library)
        let request = RetentionRequests.placeImage(
            imageID: RetentionPushSteps.uploadPlaceholder(path: "/tmp/wide.png", appID: "app-1"), pixelWidth: 4000, pixelHeight: 1000
        )
        let error = await #expect(throws: RetentionPushError.self) {
            try await RetentionPushSteps.resolving(request, known: [:], via: transport) { _ in }
        }
        guard case let .noPlacementGroup(width, height) = error else { Issue.record("\(String(describing: error))"); return }
        #expect(width == 4000 && height == 1000)
        #expect(library.log.isEmpty)
    }

    @Test func aLocalImageIsUploadedOnceAndPlacedByItsID() async throws {
        let file = try Fixtures.png(width: 3840, height: 1000)
        defer { try? FileManager.default.removeItem(at: file) }
        let size = try Data(contentsOf: file).count
        let library = FakeAssetLibrary(.init(processingPolls: 0))
        let transport = RetentionPushTransport(push: FakePushTransport(remote: [AssetLibraryRequests.refDataPath: Self.refData]), library: library)
        let request = RetentionRequests.placeImage(
            imageID: RetentionPushSteps.uploadPlaceholder(path: file.path, appID: "app-1"), pixelWidth: 3840, pixelHeight: 1000
        )

        let first = try await RetentionPushSteps.resolving(request, known: [:], via: transport) { _ in }
        #expect(placement(of: first.request).imageID == "image-1")
        #expect(library.log.contains("reserve image \(file.lastPathComponent) \(size) RETENTION_ASSETS"))
        #expect(library.log.contains("commit image-1"))
        #expect(library.uploaded("image-1")?.count == size)
        #expect(library.referenceNames.first?.hasPrefix("Retention · \(file.deletingPathExtension().lastPathComponent) · ") == true)

        let retry = try await RetentionPushSteps.resolving(request, known: first.created, via: transport) { _ in }
        #expect(placement(of: retry.request).imageID == "image-1")
        #expect(library.log.count { $0.hasPrefix("reserve") } == 1)
    }

    @Test func anImageAppleRefusesSaysWhy() async throws {
        let upload = try #require(RetentionImageUpload(in: RetentionRequests.placeImage(
            imageID: RetentionPushSteps.uploadPlaceholder(path: "/tmp/clear.png", appID: "app-1"), pixelWidth: 3840, pixelHeight: 1000
        )))
        let library = FakeAssetLibrary(.init(processingFailures: ["clear": AssetLibraryStateDetail(code: "IMAGE_ALPHA_NOT_ALLOWED", message: nil)]))
        let transport = RetentionPushTransport(push: FakePushTransport(), library: library)
        let error = await #expect(throws: RetentionPushError.self) {
            try await upload.send(via: transport, readFile: { _ in Data([1, 2]) }, sleep: { _ in }, suffix: "T1")
        }
        guard case let .imageRefused(state, details) = error else { Issue.record("\(String(describing: error))"); return }
        #expect(state == "FAILED")
        #expect(details?.contains("IMAGE_ALPHA_NOT_ALLOWED") == true)
    }

    // MARK: - Offers

    @Test func anOfferIsCreatedWithTheUSPriceAndEveryEqualizedOne() async throws {
        let request = RetentionRequests.createOffer(RetentionSampleData.offers[0])
        let create = try #require(RetentionOfferCreate(request))
        let points = Data(#"""
        {"data": [{"type": "subscriptionPricePoints", "id": "pp-us-249", "attributes": {"customerPrice": "2.49"}},
                  {"type": "subscriptionPricePoints", "id": "pp-us-299", "attributes": {"customerPrice": "2.99"}}]}
        """#.utf8)
        let equalized = Data(#"""
        {"data": [{"type": "subscriptionPricePoints", "id": "pp-de", "relationships": {"territory": {"data": {"type": "territories", "id": "DEU"}}}},
                  {"type": "subscriptionPricePoints", "id": "pp-jp", "relationships": {"territory": {"data": {"type": "territories", "id": "JPN"}}}},
                  {"type": "subscriptionPricePoints", "id": "pp-us", "relationships": {"territory": {"data": {"type": "territories", "id": "USA"}}}}]}
        """#.utf8)
        let push = FakePushTransport(
            remote: [create.pricePointsPath(territoryID: "USA"): points, create.equalizationsPath(pricePointID: "pp-us-249"): equalized],
            responses: [RetentionRequests.offersPath: Self.created("retentionOffers", "ro-1")]
        )
        var made: [String] = []
        let handled = try await RetentionPushSteps.sendSetupStep(request, via: push) { _ in } created: { made.append("\($0) \($1)") }

        #expect(handled)
        #expect(made == ["retentionOffers ro-1"])
        let sent = try #require(push.sent.first)
        let object = Fixtures.object(sent)
        let included = object["included"] as? [[String: Any]] ?? []
        let pointIDs = included.compactMap { (($0["relationships"] as? [String: Any])?["subscriptionPricePoint"] as? [String: Any])?["data"] as? [String: Any] }
            .compactMap { $0["id"] as? String }
        #expect(pointIDs == ["pp-us-249", "pp-de", "pp-jp"])
        let prices = ((Fixtures.data(sent)["relationships"] as? [String: Any])?["prices"] as? [String: Any])?["data"] as? [[String: Any]]
        #expect(prices?.compactMap { $0["id"] as? String } == ["${price1}", "${price2}", "${price3}"])
        #expect(!(String(data: sent.body ?? Data(), encoding: .utf8) ?? "").contains("{retentionOfferPrices"))
    }

    @Test func aPriceWithoutAPricePointNamesTheNearestOnes() async throws {
        var offer = RetentionSampleData.offers[0]
        offer.usPrice = Decimal(string: "2.5")
        let request = RetentionRequests.createOffer(offer)
        let create = try #require(RetentionOfferCreate(request))
        let points = Data(#"{"data": [{"id": "a", "attributes": {"customerPrice": "2.49"}}, {"id": "b", "attributes": {"customerPrice": "2.99"}}]}"#.utf8)
        let push = FakePushTransport(remote: [create.pricePointsPath(territoryID: "USA"): points])

        let error = await #expect(throws: RetentionPushError.self) { try await create.send(via: push) { _ in } }
        guard case let .noPricePoint(price, nearest) = error else { Issue.record("\(String(describing: error))"); return }
        #expect(price == Decimal(string: "2.5"))
        #expect(try nearest == [#require(Decimal(string: "2.49")), #require(Decimal(string: "2.99"))])
        #expect(push.sent.isEmpty)
    }

    // MARK: - Messages and review

    @Test func aMessageARetriedPushMadeIsFoundByName() async throws {
        let request = RetentionRequests.createMessage(appID: "app-1", referenceName: "Before you go")
        let create = try #require(RetentionMessageCreate(request))
        let found = Data(#"{"data": [{"type": "retentionMessages", "id": "rm-7", "attributes": {"referenceName": "Before you go"}}]}"#.utf8)
        let push = FakePushTransport(
            createFailures: [RetentionRequests.messagesPath: AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR", detail: "Taken")],
            remote: [create.lookupPath: found]
        )
        var made: [String] = []
        let handled = try await RetentionPushSteps.sendSetupStep(request, via: push) { _ in } created: { made.append("\($0) \($1)") }
        #expect(handled)
        #expect(made == ["retentionMessages rm-7"])
    }

    @Test func aRefusedReviewSubmissionSaysWhy() async {
        let request = RetentionRequests.createReviewSubmission(appID: "app-1")
        let push = FakePushTransport(createFailures: [
            RetentionRequests.reviewSubmissionsPath: AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR", detail: "A submission is open"),
        ])
        let error = await #expect(throws: RetentionPushError.self) {
            try await RetentionPushSteps.sendSetupStep(request, via: push) { _ in } created: { _, _ in }
        }
        guard case let .submissionRefused(detail) = error else { Issue.record("\(String(describing: error))"); return }
        #expect(detail == "A submission is open")
    }

    @Test func otherRequestsAreLeftToThePush() async throws {
        let request = PushRequest(method: .patch, path: "/v1/apps/1")
        let handled = try await RetentionPushSteps.sendSetupStep(request, via: FakePushTransport()) { _ in } created: { _, _ in }
        #expect(!handled)
    }

    // MARK: - A whole push

    @Test func aNewImageMessageGoesThroughReviewAndPush() async {
        var message = Fixtures.englishDraft()
        message.kind = .image
        message.image = RetentionSampleData.lake
        message.texts["de-DE"] = RetentionText(header: "Alles bleibt deins", body: "Wenn du kündigst, bleiben deine Einträge.")
        let queue = ChangeQueue()
        queue.upsert(Fixtures.builder(messages: [message]).change(for: message, messageCount: 1))
        let paths = [
            RetentionRequests.messagesPath: Self.created("retentionMessages", "rm-1"),
            RetentionRequests.placementsPath: Self.created("appAssetLibraryPlacements", "pl-1"),
            RetentionRequests.versionsPath: Self.created("retentionMessageVersions", "rv-1"),
            RetentionRequests.localizationsPath: Self.created("retentionMessageLocalizations", "rl-1"),
            RetentionRequests.reviewSubmissionsPath: Self.created("reviewSubmissions", "rs-1"),
            RetentionRequests.reviewItemsPath: Self.created("reviewSubmissionItems", "ri-1"),
        ]
        let transport = FakePushTransport(remote: [AssetLibraryRequests.refDataPath: Self.refData], responses: paths)
        let push = PushController(queue: queue, history: PushHistory(), transport: transport)

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(push.items.first?.status == .done)
        #expect(queue.changes.isEmpty)
        let sent = transport.sent
        #expect(sent.map { "\($0.method.rawValue) \($0.path)" } == [
            "POST /v1/retentionMessages",
            "PATCH /v1/subscriptions/\(Fixtures.monthly.id)/relationships/retentionMessage",
            "POST /v1/appAssetLibraryPlacements",
            "POST /v1/retentionMessageVersions",
            "POST /v1/retentionMessageLocalizations",
            "POST /v1/retentionMessageLocalizations",
            "POST /v1/reviewSubmissions",
            "POST /v1/reviewSubmissionItems",
            "PATCH /v1/reviewSubmissions/rs-1",
        ])
        #expect(Fixtures.data(sent[1])["id"] as? String == "rm-1")
        #expect(placement(of: sent[2]).group == "RETENTION_UNIVERSAL")
        let version = Fixtures.data(sent[3])["relationships"] as? [String: Any]
        #expect(((version?["placement"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String == "pl-1")
        #expect(((version?["retentionMessage"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String == "rm-1")
        let item = Fixtures.data(sent[7])["relationships"] as? [String: Any]
        #expect(((item?["retentionMessageVersion"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String == "rv-1")
        #expect(((item?["reviewSubmission"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String == "rs-1")
        #expect(!sent.contains { String(data: $0.body ?? Data(), encoding: .utf8)?.contains("{createdID") == true })
    }
}
#endif
