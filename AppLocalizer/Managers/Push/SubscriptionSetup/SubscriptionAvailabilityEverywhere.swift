//
//  SubscriptionAvailabilityEverywhere.swift
//  AppLocalizer
//

import Foundation

/// A new subscription's availability in every country or region: a
/// `POST /v1/subscriptionAvailabilities` whose one territory is
/// `{everyTerritory}`. The push fills in the territories App Store Connect
/// has (`GET /v1/territories`, read once per push), not AppLocalizer's own
/// table, which is approximate: App Store Connect refuses some of its
/// territories (Samoa, `ENTITY_ERROR.INVALID_TERRITORY`).
///
/// Changes queued before the placeholder list every territory of that
/// table instead; they're sent the same way.
struct SubscriptionAvailabilityEverywhere: Hashable, Sendable {
    /// May be `{createdID:subscriptions}` until the push fills it in.
    var subscriptionID: String
    var availableInNewTerritories: Bool

    static let placeholder = "{everyTerritory}"
    static let path = "/v1/subscriptionAvailabilities"

    /// `GET` every territory, IDs only.
    static let territoriesPath = "/v1/territories?fields%5Bterritories%5D=currency&limit=200"

    /// The queued request.
    static func request(subscriptionID: String, availableInNewTerritories: Bool = true) -> PushRequest {
        SubscriptionAvailabilityEverywhere(subscriptionID: subscriptionID, availableInNewTerritories: availableInNewTerritories)
            .request(territoryIDs: [placeholder])
    }

    init(subscriptionID: String, availableInNewTerritories: Bool) {
        self.subscriptionID = subscriptionID
        self.availableInNewTerritories = availableInNewTerritories
    }

    /// The request when it asks for every territory: the placeholder, or
    /// all of `TerritoryCatalog.standard` (queued before it). Nil for any
    /// other request.
    init?(_ request: PushRequest) {
        guard request.method == .post, request.path == Self.path, let body = request.body,
              let object = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let data = object["data"] as? [String: Any],
              let relationships = data["relationships"] as? [String: Any],
              let subscription = (relationships["subscription"] as? [String: Any])?["data"] as? [String: Any],
              let subscriptionID = subscription["id"] as? String,
              let territories = (relationships["availableTerritories"] as? [String: Any])?["data"] as? [[String: Any]]
        else { return nil }
        let ids = territories.compactMap { $0["id"] as? String }
        guard ids == [Self.placeholder] || Set(ids) == Self.tableIDs else { return nil }
        self.subscriptionID = subscriptionID
        availableInNewTerritories = (data["attributes"] as? [String: Any])?["availableInNewTerritories"] as? Bool ?? true
    }

    private static let tableIDs = Set(TerritoryCatalog.standard.territories.map(\.id))

    /// The `POST` with these territories.
    func request(territoryIDs: [String]) -> PushRequest {
        let body: [String: Any] = [
            "data": [
                "type": "subscriptionAvailabilities",
                "attributes": ["availableInNewTerritories": availableInNewTerritories],
                "relationships": [
                    "subscription": ["data": ["type": "subscriptions", "id": subscriptionID]],
                    "availableTerritories": ["data": territoryIDs.map { ["type": "territories", "id": $0] }],
                ],
            ],
        ]
        let data = (try? JSONSerialization.data(withJSONObject: body, options: [.sortedKeys, .withoutEscapingSlashes])) ?? Data()
        return PushRequest(method: .post, path: Self.path, body: data)
    }

    /// Every territory App Store Connect has, following `links.next`.
    /// `note` gets each response's rate limit.
    @MainActor
    static func territoryIDs(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> [String] {
        var next: String? = territoriesPath
        var ids: [String] = []
        while let page = next {
            let response = try await transport.fetch(page)
            note(response.rateLimit)
            let object = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any]
            ids += (object?["data"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
            next = (object?["links"] as? [String: Any])?["next"] as? String
        }
        guard !ids.isEmpty else { throw AppStoreConnectError.unexpectedPayload }
        return ids
    }
}
