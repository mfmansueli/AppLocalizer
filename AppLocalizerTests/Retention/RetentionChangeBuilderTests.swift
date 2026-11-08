//
//  RetentionChangeBuilderTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What Review & Push sends for a retention message or offer (App Store
/// Connect API 4.6): a new message, a new version over a live one or edits
/// into one still in the works, the image placement first, offers linked
/// to the subscription, and the review submission without an app version;
/// and the queued change read back after a relaunch.
@MainActor
@Suite("Retention change builder")
struct RetentionChangeBuilderTests {
    private typealias Fixtures = RetentionTestFixtures

    private func paths(_ requests: [PushRequest]) -> [String] {
        requests.map { "\($0.method.rawValue) \($0.path)" }
    }

    @Test func aNewMessageIsCreatedAssignedVersionedAndSubmitted() {
        var message = Fixtures.englishDraft()
        message.subscriptionIDs = [Fixtures.monthly.id, Fixtures.annual.id]
        message.texts["de-DE"] = RetentionText(header: "Bleib", body: "Deine Einträge bleiben.", origin: .translated)
        let requests = Fixtures.builder(messages: [message]).requests(for: message)

        #expect(paths(requests) == [
            "POST /v1/retentionMessages",
            "PATCH /v1/subscriptions/\(Fixtures.monthly.id)/relationships/retentionMessage",
            "PATCH /v1/subscriptions/\(Fixtures.annual.id)/relationships/retentionMessage",
            "POST /v1/retentionMessageVersions",
            "POST /v1/retentionMessageLocalizations",
            "POST /v1/retentionMessageLocalizations",
            "POST /v1/reviewSubmissions",
            "POST /v1/reviewSubmissionItems",
            "PATCH /v1/reviewSubmissions/{createdID:reviewSubmissions}",
        ])
        #expect(Fixtures.attributes(requests[0])["referenceName"] as? String == "Before you go")
        let assign = Fixtures.data(requests[1])
        #expect(assign["id"] as? String == "{createdID:retentionMessages}")
        let version = Fixtures.data(requests[3])["relationships"] as? [String: Any]
        #expect(version?["placement"] == nil)
        #expect(Fixtures.attributes(requests[4])["locale"] as? String == "en-US")
        #expect(Fixtures.attributes(requests[5])["locale"] as? String == "de-DE")
        let item = Fixtures.data(requests[7])["relationships"] as? [String: Any]
        #expect(item?["retentionMessageVersion"] != nil)
        #expect(Fixtures.attributes(requests[8])["submitted"] as? Bool == true)
    }

    @Test func anImageIsPlacedBeforeTheVersionThatShowsIt() throws {
        var message = Fixtures.englishDraft()
        message.kind = .image
        message.image = RetentionSampleData.window
        let requests = Fixtures.builder(messages: [message]).requests(for: message)

        let placement = try #require(requests.first { $0.path == RetentionRequests.placementsPath })
        let versionIndex = try #require(requests.firstIndex { $0.path == RetentionRequests.versionsPath })
        #expect(try #require(requests.firstIndex(of: placement)) < versionIndex)
        let attributes = Fixtures.attributes(placement)
        #expect(attributes["placementType"] as? String == "RETENTION_MESSAGE_ASSET")
        #expect(attributes["placementGroup"] as? String == "{retentionPlacementGroup:3840x1200}")
        let image = (Fixtures.data(placement)["relationships"] as? [String: Any])?["image"] as? [String: Any]
        #expect((image?["data"] as? [String: Any])?["id"] as? String == "asset.window")
        let version = Fixtures.data(requests[versionIndex])["relationships"] as? [String: Any]
        #expect(((version?["placement"] as? [String: Any])?["data"] as? [String: Any])?["id"] as? String == "{createdID:appAssetLibraryPlacements}")
    }

    @Test func aLocalImageIsUploadedByThePush() throws {
        var message = Fixtures.englishDraft()
        message.kind = .image
        message.image = RetentionImage(name: "Made", pixelWidth: 3840, pixelHeight: 1000, localPath: "/tmp/made one.png", hasAlpha: false, isPNG: true)
        let requests = Fixtures.builder(messages: [message]).requests(for: message)
        let placement = try #require(requests.first { $0.path == RetentionRequests.placementsPath })
        let upload = try #require(RetentionImageUpload(in: placement))
        #expect(upload.appID == Fixtures.app.id)
        #expect(upload.path == "/tmp/made one.png")
        #expect(upload.fileName == "made one.png")
    }

    @Test func aLiveMessageGetsANewVersionWithEveryLanguage() {
        var message = Fixtures.live()
        message.texts["de-DE"]?.body = "Deine Einträge bleiben."
        let requests = Fixtures.builder(messages: [message]).requests(for: message)

        #expect(!requests.contains { $0.path == RetentionRequests.messagesPath })
        #expect(!requests.contains { $0.path.hasSuffix("/relationships/retentionMessage") })
        let version = requests.first { $0.path == RetentionRequests.versionsPath }
        #expect(version.map { (Fixtures.data($0)["relationships"] as? [String: Any])?["retentionMessage"] != nil } == true)
        #expect(requests.count { $0.path == RetentionRequests.localizationsPath } == 18)
        #expect(requests.contains { $0.path == RetentionRequests.reviewSubmissionsPath })
    }

    @Test func aVersionStillInTheWorksTakesEditsInPlace() throws {
        var message = Fixtures.live(state: .prepareForSubmission)
        let germanID = try #require(message.remote?.localizations["de-DE"]?.id)
        let frenchID = try #require(message.remote?.localizations["fr-FR"]?.id)
        message.texts["de-DE"]?.body = "Deine Einträge bleiben."
        message.texts["fr-FR"] = .empty
        message.texts["fi"] = RetentionText(header: "Pysy", body: "Merkintäsi säilyvät.")
        let requests = Fixtures.builder(messages: [message]).requests(for: message)

        #expect(!requests.contains { $0.path == RetentionRequests.versionsPath })
        #expect(paths(requests).prefix(3) == [
            "PATCH /v1/retentionMessageLocalizations/\(germanID)",
            "DELETE /v1/retentionMessageLocalizations/\(frenchID)",
            "POST /v1/retentionMessageLocalizations",
        ])
        let created = requests[2]
        let version = (Fixtures.data(created)["relationships"] as? [String: Any])?["retentionMessageVersion"] as? [String: Any]
        #expect((version?["data"] as? [String: Any])?["id"] as? String == RetentionSampleData.versionID)
        #expect(Fixtures.attributes(created)["locale"] as? String == "fi")
    }

    @Test func offersAreShownWithAWithOfferMessageAndHiddenOtherwise() {
        var offers = RetentionSampleData.offers
        offers[1].isShown = true
        var message = Fixtures.live()
        message.kind = .offer
        var requests = Fixtures.builder(messages: [message], offers: offers).requests(for: message)
        #expect(paths(requests).contains("POST /v1/subscriptions/\(Fixtures.monthly.id)/relationships/retentionMessageOffers"))
        #expect(!paths(requests).contains("POST /v1/subscriptions/\(Fixtures.annual.id)/relationships/retentionMessageOffers"))
        #expect(!requests.contains { $0.path == RetentionRequests.reviewSubmissionsPath })

        message.kind = .message
        requests = Fixtures.builder(messages: [message], offers: offers).requests(for: message)
        #expect(paths(requests) == ["DELETE /v1/subscriptions/\(Fixtures.annual.id)/relationships/retentionMessageOffers"])
    }

    @Test func aNewOfferIsCreatedWithItsUSPriceAndShown() throws {
        let draft = RetentionOfferDraft(name: "Half price", subscriptionID: Fixtures.monthly.id, mode: .payAsYouGo, months: 3, priceText: "2.49")
        let offer = try #require(draft.offer(for: Fixtures.monthly, existing: []))
        let change = Fixtures.builder().offerChange(for: offer, source: .assistant(client: "Claude Code"), evidence: ["Plans.swift:22 — 4.99"])

        #expect(change.id == "retention.offer.\(Fixtures.app.id).\(Fixtures.monthly.id).retention.half_price")
        #expect(change.groupID == nil)
        #expect(paths(change.requests) == [
            "POST /v1/retentionOffers",
            "POST /v1/subscriptions/\(Fixtures.monthly.id)/relationships/retentionMessageOffers",
        ])
        let attributes = Fixtures.attributes(change.requests[0])
        #expect(attributes["offerMode"] as? String == "PAY_AS_YOU_GO")
        #expect(attributes["duration"] as? String == "ONE_MONTH")
        #expect(attributes["periodCount"] as? Int == 3)
        #expect(attributes["customerEligibilityPaidSubscriptionDurationInMonths"] as? Int == 1)
        let create = try #require(RetentionOfferCreate(change.requests[0]))
        #expect(create.price?.territoryID == "USA")
        #expect(create.price?.amount == Decimal(string: "2.49"))
        #expect(change.creation?.fields.contains { $0.id == "evidence" } == true)
        #expect(RetentionQueuedChanges.offer(from: change)?.offerID == "retention.half_price")
    }

    @Test func aQueuedMessageReadsBackAfterARelaunch() throws {
        var message = Fixtures.englishDraft()
        message.subscriptionIDs = [Fixtures.monthly.id, Fixtures.annual.id]
        message.texts["ja"] = RetentionText(header: "書いたこと", body: "日記は残ります。", origin: .assistant(client: "Claude Code"))
        message.kind = .image
        message.image = RetentionSampleData.lake
        let builder = Fixtures.builder(messages: [message])
        let change = builder.change(for: message, messageCount: 1)

        #expect(change.blockedReason == nil)
        #expect(change.title == "Retention message · Before you go")
        let read = try #require(RetentionQueuedChanges.message(from: change, remote: nil))
        #expect(read.id == "draft-1")
        #expect(read.referenceName == "Before you go")
        #expect(Set(read.subscriptionIDs) == Set(message.subscriptionIDs))
        #expect(read.kind == .image)
        #expect(read.image?.assetID == "asset.lake")
        #expect(read.text(for: "ja").hasSameWords(as: message.text(for: "ja")))
        #expect(read.text(for: "ja").origin == .assistant(client: "Claude Code"))
        #expect(RetentionChangeBuilder.messageID(of: change) == "draft-1")
        #expect(RetentionChangeBuilder.owns(change))
    }

    @Test func aBlockedMessageSaysWhy() {
        var message = Fixtures.englishDraft()
        message.texts["de-DE"] = RetentionText(header: "Bleib", body: String(repeating: "x", count: 145))
        let change = Fixtures.builder(messages: [message]).change(for: message, messageCount: 1)
        #expect(change.blockedReason == RetentionMessageProblem.tooLong(languages: ["German"]).message)
    }
}
#endif
