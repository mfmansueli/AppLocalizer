//
//  SubscriptionAvailabilityEverywhereTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A new subscription's availability in every territory App Store Connect
/// has, not the app's own approximate table.
@MainActor
@Suite("SubscriptionAvailabilityEverywhere")
struct SubscriptionAvailabilityEverywhereTests {
    private static func availability(subscriptionID: String = "sub9", territories: [String], newTerritories: Bool = true) -> PushRequest {
        let body: [String: Any] = ["data": [
            "type": "subscriptionAvailabilities",
            "attributes": ["availableInNewTerritories": newTerritories],
            "relationships": [
                "subscription": ["data": ["type": "subscriptions", "id": subscriptionID]],
                "availableTerritories": ["data": territories.map { ["type": "territories", "id": $0] }],
            ],
        ]]
        return PushRequest(method: .post, path: "/v1/subscriptionAvailabilities", body: try? JSONSerialization.data(withJSONObject: body))
    }

    @Test func readsThePlaceholder() throws {
        let request = SubscriptionAvailabilityEverywhere.request(subscriptionID: "{createdID:subscriptions}")
        let step = try #require(SubscriptionAvailabilityEverywhere(request))
        #expect(step.subscriptionID == "{createdID:subscriptions}")
        #expect(step.availableInNewTerritories)
    }

    @Test func readsTheTableTheOldChangesList() throws {
        let table = TerritoryCatalog.standard.territories.map(\.id)
        #expect(table.contains("WSM"))
        let step = try #require(SubscriptionAvailabilityEverywhere(Self.availability(subscriptionID: "6831136732", territories: table.reversed())))
        #expect(step.subscriptionID == "6831136732")
    }

    @Test func someTerritoriesAreNotEveryTerritory() {
        let table = TerritoryCatalog.standard.territories.map(\.id)
        #expect(SubscriptionAvailabilityEverywhere(Self.availability(territories: ["USA", "BRA"])) == nil)
        #expect(SubscriptionAvailabilityEverywhere(Self.availability(territories: Array(table.dropLast()))) == nil)
        let elsewhere = PushRequest(method: .post, path: "/v1/appAvailabilities", body: Self.availability(territories: table).body)
        #expect(SubscriptionAvailabilityEverywhere(elsewhere) == nil)
    }

    @Test func sendsTheTerritoriesItIsGiven() throws {
        let step = SubscriptionAvailabilityEverywhere(subscriptionID: "sub9", availableInNewTerritories: false)
        let request = step.request(territoryIDs: ["USA", "BRA"])
        let object = try #require(request.body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let data = try #require(object["data"] as? [String: Any])
        #expect((data["attributes"] as? [String: Any])?["availableInNewTerritories"] as? Bool == false)
        let relationships = try #require(data["relationships"] as? [String: Any])
        let territories = (relationships["availableTerritories"] as? [String: Any])?["data"] as? [[String: Any]]
        #expect(territories?.compactMap { $0["id"] as? String } == ["USA", "BRA"])
    }

    @Test func followsTheNextPages() async throws {
        let next = "https://api.appstoreconnect.apple.com/v1/territories?cursor=Mg&fields%5Bterritories%5D=currency&limit=200"
        let transport = FakePushTransport(remote: [
            SubscriptionAvailabilityEverywhere.territoriesPath: Data(#"{"data":[{"id":"USA"},{"id":"BRA"}],"links":{"next":"\#(next)"}}"#.utf8),
            next: Data(#"{"data":[{"id":"GBR"}],"links":{}}"#.utf8),
        ])
        let ids = try await SubscriptionAvailabilityEverywhere.territoryIDs(via: transport) { _ in }
        #expect(ids == ["USA", "BRA", "GBR"])
        #expect(transport.fetched == [SubscriptionAvailabilityEverywhere.territoriesPath, next])
    }

    @Test func noTerritoriesIsAnError() async {
        let transport = FakePushTransport(remote: [SubscriptionAvailabilityEverywhere.territoriesPath: Data(#"{"data":[]}"#.utf8)])
        await #expect(throws: AppStoreConnectError.unexpectedPayload) {
            try await SubscriptionAvailabilityEverywhere.territoryIDs(via: transport) { _ in }
        }
    }
}
