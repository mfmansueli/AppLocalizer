//
//  PushControllerSubscriptionSetupTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Pushing a new subscription: the group found or created once, the
/// subscription, its texts into versions, availability, and the starting
/// price equalized everywhere, each step resuming after a failure.
@MainActor
@Suite("PushController · new subscriptions")
struct PushControllerSubscriptionSetupTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()
    private let builder = NewSubscriptionChangeBuilder(app: NewSubscriptionChangeBuilderTests.app)

    private static let groupLookup = "/v1/apps/app1/subscriptionGroups?filter%5BreferenceName%5D=Bruma%20Premium"
        + "&fields%5BsubscriptionGroups%5D=referenceName&limit=200"
    private static let pricePoints = "/v1/subscriptions/sub9/pricePoints?filter%5Bterritory%5D=USA"
        + "&fields%5BsubscriptionPricePoints%5D=customerPrice&limit=8000"
    private static let equalizations = "/v1/subscriptionPricePoints/p2/equalizations?include=territory"
        + "&fields%5BsubscriptionPricePoints%5D=customerPrice,territory&fields%5Bterritories%5D=currency&limit=200"
    private static let prices = "/v1/subscriptions/sub9/prices?include=territory&fields%5BsubscriptionPrices%5D=territory"
        + "&fields%5Bterritories%5D=currency&limit=200"

    private static let subscriptionLookup = "/v1/subscriptionGroups/grp9/subscriptions?filter%5BproductId%5D=com%2Elima%2Ebruma%2Epremium%2Emonthly"
        + "&fields%5Bsubscriptions%5D=productId&limit=200"

    private static func created(_ type: String, _ id: String) -> Data {
        Data(#"{"data":{"type":"\#(type)","id":"\#(id)"}}"#.utf8)
    }

    private static func inTerritory(_ id: String, _ territory: String) -> String {
        #"{"id":"\#(id)","relationships":{"territory":{"data":{"type":"territories","id":"\#(territory)"}}}}"#
    }

    /// Apple's side: no group yet, a subscription with an editable texts
    /// version, $8.99 and $9.99 in the US, equalized in Brazil and the UK,
    /// and a UK price already there.
    private static func transport(
        remote extra: [String: Data] = [:],
        failures: [String: any Error] = [:],
        createFailures: [String: any Error] = [:]
    ) -> FakePushTransport {
        var remote: [String: Data] = [
            "/v1/subscriptions/sub9/versions?limit=200": Data(#"{"data":[{"id":"sv1","attributes":{"version":1,"state":"PREPARE_FOR_SUBMISSION"}}]}"#.utf8),
            pricePoints: Data(#"{"data":[{"id":"p1","attributes":{"customerPrice":"8.99"}},{"id":"p2","attributes":{"customerPrice":"9.99"}}]}"#.utf8),
            equalizations: Data(#"{"data":[\#(inTerritory("e1", "BRA")),\#(inTerritory("e2", "GBR"))]}"#.utf8),
            prices: Data(#"{"data":[\#(inTerritory("price1", "GBR"))]}"#.utf8),
            SubscriptionAvailabilityEverywhere.territoriesPath: Data(#"{"data":[{"id":"USA"},{"id":"BRA"},{"id":"GBR"}]}"#.utf8),
        ]
        remote.merge(extra) { $1 }
        return FakePushTransport(
            failures: failures,
            createFailures: createFailures,
            remote: remote,
            responses: [
                "/v1/subscriptionGroups": created("subscriptionGroups", "grp9"),
                "/v1/subscriptions": created("subscriptions", "sub9"),
                "/v1/subscriptionGroupVersions": created("subscriptionGroupVersions", "gv1"),
                "/v1/subscriptionAvailabilities": created("subscriptionAvailabilities", "av1"),
            ]
        )
    }

    private func push(_ changes: [PendingChange], via transport: FakePushTransport) async -> PushController {
        let controller = PushController(queue: queue, history: history, transport: transport)
        queue.upsert(contentsOf: changes)
        controller.push(queue.changes)
        await controller.waitUntilFinished()
        return controller
    }

    private func relationshipIDs(_ request: PushRequest, _ name: String) -> [String] {
        let object = request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let relationships = (object?["data"] as? [String: Any])?["relationships"] as? [String: Any]
        let data = (relationships?[name] as? [String: Any])?["data"] as? [[String: Any]]
        return data?.compactMap { $0["id"] as? String } ?? []
    }

    private func relationshipID(_ request: PushRequest, _ name: String) -> String? {
        let object = request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        let relationships = (object?["data"] as? [String: Any])?["relationships"] as? [String: Any]
        let data = (relationships?[name] as? [String: Any])?["data"]
        return (data as? [String: Any])?["id"] as? String
    }

    @Test func aNewSubscriptionIsCreatedStepByStep() async {
        let transport = Self.transport()
        let controller = await push([builder.change(for: NewSubscriptionChangeBuilderTests.monthly())], via: transport)

        #expect(controller.doneCount == 1)
        #expect(queue.changes.isEmpty)
        #expect(transport.sent.map(\.path) == [
            "/v1/subscriptionGroups",
            "/v1/subscriptions",
            "/v1/subscriptionGroupVersions",
            "/v2/subscriptionGroupLocalizations",
            "/v2/subscriptionLocalizations",
            "/v1/subscriptionAvailabilities",
            "/v1/subscriptionPrices",
            "/v1/subscriptionPrices",
        ])
        let sent = transport.sent
        #expect(relationshipID(sent[1], "group") == "grp9")
        #expect(relationshipID(sent[2], "subscriptionGroup") == "grp9")
        #expect(relationshipID(sent[3], "version") == "gv1")
        #expect(relationshipID(sent[4], "version") == "sv1")
        #expect(relationshipID(sent[5], "subscription") == "sub9")
        // Available in the territories App Store Connect has, not the app's own table.
        #expect(relationshipIDs(sent[5], "availableTerritories") == ["USA", "BRA", "GBR"])
        // The US at $9.99 and Brazil at its equalized point; the UK keeps its price.
        #expect(sent[6...].map { relationshipID($0, "territory") } == ["USA", "BRA"])
        #expect(sent[6...].map { relationshipID($0, "subscriptionPricePoint") } == ["p2", "e1"])
        // Every placeholder was filled in before it went.
        let texts = sent.map { $0.path + (String(data: $0.body ?? Data(), encoding: .utf8) ?? "") }
        for placeholder in ["{createdID", "{subscriptionGroup:", "{inAppDraft:", "{startingPrice:", "{everyTerritory}"] {
            #expect(!texts.contains { $0.contains(placeholder) })
        }
        #expect(transport.fetched.first == Self.groupLookup)
    }

    @Test func twoSubscriptionsInANewGroupShareIt() async {
        let transport = Self.transport()
        var annual = NewSubscriptionChangeBuilderTests.monthly()
        annual.productID = "com.lima.bruma.premium.annual"
        annual.referenceName = "Bruma Premium Annual"
        annual.period = .oneYear
        _ = await push([builder.change(for: NewSubscriptionChangeBuilderTests.monthly()), builder.change(for: annual)], via: transport)

        #expect(transport.sent.count { $0.path == "/v1/subscriptionGroups" } == 1)
        #expect(transport.fetched.count { $0 == Self.groupLookup } == 1)
        #expect(transport.sent.filter { $0.path == "/v1/subscriptions" }.map { relationshipID($0, "group") } == ["grp9", "grp9"])
        // App Store Connect's territories are read once for both.
        #expect(transport.fetched.count { $0 == SubscriptionAvailabilityEverywhere.territoriesPath } == 1)
    }

    /// After a push App Store Connect refused at Samoa: the group, the
    /// subscription and both texts are there, without availability or
    /// prices. The app was reopened, so the push starts at the first
    /// request again and finishes without making anything twice.
    @Test func aPushThatStoppedResumesFromTheFirstRequest() async {
        let refusal = AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE", detail: "The product ID is in use.")
        let subscriptions = #"[{"id":"sub1","attributes":{"productId":"com.lima.bruma.premium"}},"#
            + #"{"id":"sub9","attributes":{"productId":"com.lima.bruma.premium.monthly"}}]"#
        let editable = #"{"data":[{"id":"gv1","attributes":{"version":1,"state":"PREPARE_FOR_SUBMISSION"}}]}"#
        let transport = Self.transport(
            remote: [
                Self.groupLookup: Data(#"{"data":[{"id":"grp9","attributes":{"referenceName":"Bruma Premium"}}]}"#.utf8),
                Self.subscriptionLookup: Data(#"{"data":\#(subscriptions)}"#.utf8),
                "/v1/subscriptionGroups/grp9/versions?limit=200": Data(editable.utf8),
                "/v1/subscriptionGroupVersions/gv1/localizations?limit=200": Data(#"{"data":[{"id":"gl1","attributes":{"locale":"en-US"}}]}"#.utf8),
                "/v1/subscriptionVersions/sv1/localizations?limit=200": Data(#"{"data":[{"id":"sl1","attributes":{"locale":"en-US"}}]}"#.utf8),
            ],
            createFailures: ["/v1/subscriptions": refusal]
        )
        let controller = await push([builder.change(for: NewSubscriptionChangeBuilderTests.monthly())], via: transport)

        #expect(controller.doneCount == 1)
        #expect(queue.changes.isEmpty)
        // The group is found, the refused subscription looked up, both texts updated in place.
        #expect(transport.sent.map { "\($0.method.rawValue) \($0.path)" } == [
            "POST /v1/subscriptions",
            "PATCH /v2/subscriptionGroupLocalizations/gl1",
            "PATCH /v2/subscriptionLocalizations/sl1",
            "POST /v1/subscriptionAvailabilities",
            "POST /v1/subscriptionPrices",
            "POST /v1/subscriptionPrices",
        ])
        #expect(transport.fetched.contains(Self.subscriptionLookup))
        let sent = transport.sent
        #expect(relationshipID(sent[0], "group") == "grp9")
        #expect(relationshipID(sent[3], "subscription") == "sub9")
        #expect(relationshipIDs(sent[3], "availableTerritories") == ["USA", "BRA", "GBR"])
        // The US at its point and Brazil equalized; the UK keeps the price it has.
        #expect(sent[4...].map { relationshipID($0, "subscription") } == ["sub9", "sub9"])
        #expect(sent[4...].map { relationshipID($0, "territory") } == ["USA", "BRA"])
    }

    @Test func aRefusedSubscriptionTheGroupDoesntHaveFails() async throws {
        let refusal = AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: "The name is too long.")
        let transport = Self.transport(createFailures: ["/v1/subscriptions": refusal])
        let controller = await push([builder.change(for: NewSubscriptionChangeBuilderTests.monthly())], via: transport)

        let item = try #require(controller.items.first)
        guard case let .failed(text) = item.status else { Issue.record("Expected a failure, got \(item.status)"); return }
        #expect(text.contains("ENTITY_ERROR.ATTRIBUTE.INVALID"))
        #expect(item.sentRequestCount == 0)
        #expect(!transport.sent.contains { $0.path == "/v1/subscriptionAvailabilities" })
    }

    @Test func availabilityQueuedWithTheAppsTableGetsApplesTerritories() async {
        // Queued before `{everyTerritory}`: every territory of the app's table, Samoa included.
        let table = TerritoryCatalog.standard.territories.map { ["type": "territories", "id": $0.id] }
        let body: [String: Any] = ["data": [
            "type": "subscriptionAvailabilities",
            "attributes": ["availableInNewTerritories": true],
            "relationships": [
                "subscription": ["data": ["type": "subscriptions", "id": "{createdID:subscriptions}"]],
                "availableTerritories": ["data": table],
            ],
        ]]
        let old = PushRequest(method: .post, path: "/v1/subscriptionAvailabilities", body: try? JSONSerialization.data(withJSONObject: body))
        #expect(table.contains { $0["id"] == "WSM" })
        #expect(SubscriptionAvailabilityEverywhere(old)?.subscriptionID == "{createdID:subscriptions}")

        var change = builder.change(for: NewSubscriptionChangeBuilderTests.monthly())
        let index = change.requests.firstIndex { $0.path == "/v1/subscriptionAvailabilities" } ?? 0
        change.requests[index] = old
        let transport = Self.transport()
        let controller = await push([change], via: transport)

        #expect(controller.doneCount == 1)
        let availability = transport.sent.first { $0.path == "/v1/subscriptionAvailabilities" }
        #expect(availability.map { relationshipIDs($0, "availableTerritories") } == ["USA", "BRA", "GBR"])
        #expect(availability.flatMap { relationshipID($0, "subscription") } == "sub9")
    }

    @Test func availabilityInSomeTerritoriesIsSentAsItIs() {
        let some = SubscriptionAvailabilityEverywhere(subscriptionID: "sub9", availableInNewTerritories: false)
            .request(territoryIDs: ["USA", "BRA"])
        #expect(SubscriptionAvailabilityEverywhere(some) == nil)
    }

    @Test func aGroupTheAppHasByThenIsUsed() async {
        let groups = #"[{"id":"grp1","attributes":{"referenceName":"Bruma Premium Plus"}},{"id":"grp2","attributes":{"referenceName":"Bruma Premium"}}]"#
        let found = Data(#"{"data":\#(groups)}"#.utf8)
        let transport = Self.transport(remote: [Self.groupLookup: found])
        _ = await push([builder.change(for: NewSubscriptionChangeBuilderTests.monthly())], via: transport)

        #expect(!transport.sent.contains { $0.path == "/v1/subscriptionGroups" })
        #expect(transport.sent.first.flatMap { relationshipID($0, "group") } == "grp2")
    }

    @Test func aPriceAppleDoesntHaveFailsWithTheNearestOnes() async throws {
        var subscription = NewSubscriptionChangeBuilderTests.monthly()
        subscription.price = Decimal(string: "9.49")
        let transport = Self.transport()
        let controller = await push([builder.change(for: subscription)], via: transport)

        let item = try #require(controller.items.first)
        guard case let .failed(text) = item.status else { Issue.record("Expected a failure, got \(item.status)"); return }
        #expect(text.contains("$9.49"))
        #expect(text.contains("$8.99") && text.contains("$9.99"))
        #expect(item.sentRequestCount == 4)
        #expect(queue.changes.count == 1)

        controller.retryFailed()
        await controller.waitUntilFinished()
        // The retry starts at the prices: nothing is created twice.
        #expect(transport.sent.count { $0.path == "/v1/subscriptions" } == 1)
        #expect(transport.fetched.count { $0 == Self.pricePoints } == 2)
    }

    @Test func aStartingPriceForASubscriptionThatExists() async {
        let product = PricingProduct(
            id: "sub9",
            name: "Bruma Monthly",
            productID: "com.lima.bruma.monthly",
            period: .oneMonth,
            isInAppPurchase: false,
            reviewState: "Missing Metadata"
        )
        let transport = Self.transport()
        let controller = await push([builder.startingPriceChange(for: product, price: Decimal(string: "9.99") ?? 0)], via: transport)

        #expect(controller.doneCount == 1)
        #expect(transport.sent.map { relationshipID($0, "territory") } == ["USA", "BRA"])
    }

    // MARK: - Placeholders

    @Test func createdIDsAreFilledInByType() throws {
        let request = PushRequest(method: .post, path: "/v1/x/{createdID:subscriptions}", body: Data(#"{"id":"{createdID:subscriptionGroups}"}"#.utf8))
        let resolved = try request.resolvingCreatedIDs(["subscriptions": "sub9", "subscriptionGroups": "grp9"])
        #expect(resolved.path == "/v1/x/sub9")
        #expect(resolved.body == Data(#"{"id":"grp9"}"#.utf8))
        #expect(throws: PushRequestPlaceholderError.self) { try request.resolvingCreatedIDs(["subscriptions": "sub9"]) }
        // The plain `{createdID}` is left for `resolved(createdID:secret:)`.
        let plain = PushRequest(method: .patch, path: "/v1/x/{createdID}")
        #expect(try plain.resolvingCreatedIDs([:]) == plain)
    }

    @Test func aGroupPlaceholderSurvivesAnyName() throws {
        let token = SubscriptionGroupPlaceholder.placeholder(appID: "app1", referenceName: "Bruma: Premium/Plus")
        let request = try PushRequest.json(.post, "/v1/subscriptions", ["group": token])
        let placeholder = try #require(SubscriptionGroupPlaceholder(in: request))
        #expect(placeholder.appID == "app1")
        #expect(placeholder.referenceName == "Bruma: Premium/Plus")
        #expect(placeholder.token == token)
        #expect(SubscriptionGroupPlaceholder(in: PushRequest(method: .post, path: "/v1/subscriptions")) == nil)
    }
}
