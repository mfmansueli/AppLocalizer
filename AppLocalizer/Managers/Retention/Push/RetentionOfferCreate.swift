//
//  RetentionOfferCreate.swift
//  AppLocalizer
//

import Foundation

/// A new retention offer's `POST /v1/retentionOffers`. Its prices are
/// subscription price points, which the push reads when it sends it: the
/// one at the U.S. price and the ones Apple equalizes with it, each as an
/// included `retentionOfferPrices` resource (`${price1}`, …). When a retry
/// is refused because the offer ID is there by now, the push carries on
/// with that offer.
struct RetentionOfferCreate: Hashable, Sendable {
    var request: PushRequest
    var subscriptionID: String
    var offerID: String
    /// From `{retentionOfferPrices:USA:2.49}`; nil for a free offer.
    var price: (territoryID: String, amount: Decimal)? {
        guard let value else { return nil }
        let parts = value.split(separator: ":").map(String.init)
        guard parts.count == 2, let amount = RetentionJSON.decimal(parts[1]) else { return nil }
        return (parts[0], amount)
    }

    private var value: String?

    init?(_ request: PushRequest) {
        guard request.method == .post, request.path == RetentionRequests.offersPath,
              let data = RetentionRequests.object(of: request)?["data"] as? [String: Any],
              let subscriptionID = RetentionJSON.relatedID("subscription", of: data),
              let offerID = RetentionJSON.string("offerId", of: data)
        else { return nil }
        self.request = request
        self.subscriptionID = subscriptionID
        self.offerID = offerID
        value = RetentionPushSteps.token(RetentionPushSteps.offerPricesPrefix, in: request)?.value
    }

    // MARK: - Reads

    func pricePointsPath(territoryID: String) -> String {
        "/v1/subscriptions/\(subscriptionID)/pricePoints?filter%5Bterritory%5D=\(territoryID)"
            + "&fields%5BsubscriptionPricePoints%5D=customerPrice&limit=8000"
    }

    func equalizationsPath(pricePointID: String) -> String {
        "/v1/subscriptionPricePoints/\(pricePointID)/equalizations?include=territory"
            + "&fields%5BsubscriptionPricePoints%5D=customerPrice,territory&fields%5Bterritories%5D=currency&limit=200"
    }

    var lookupPath: String {
        "/v1/subscriptions/\(subscriptionID)/retentionOffers?fields%5BretentionOffers%5D=offerId&limit=200"
    }

    /// The request with every price included, from the price points' IDs.
    func request(pricePointIDs: [String]) -> PushRequest {
        guard var object = RetentionRequests.object(of: request), var data = object["data"] as? [String: Any] else { return request }
        var relationships = data["relationships"] as? [String: Any] ?? [:]
        let localIDs = pricePointIDs.indices.map { "${price\($0 + 1)}" }
        relationships["prices"] = ["data": localIDs.map { ["type": "retentionOfferPrices", "id": $0] }]
        data["relationships"] = relationships
        object["data"] = data
        object["included"] = zip(localIDs, pricePointIDs).map { localID, point in
            [
                "type": "retentionOfferPrices",
                "id": localID,
                "relationships": ["subscriptionPricePoint": ["data": ["type": "subscriptionPricePoints", "id": point]]],
            ] as [String: Any]
        }
        return RetentionRequests.request(.post, RetentionRequests.offersPath, object)
    }

    // MARK: - Sending

    /// The price points: the base territory's at the price first, then
    /// the equalized ones of every other territory.
    @MainActor
    func pricePointIDs(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> [String] {
        guard let price else { return [] }
        let points = try await RetentionJSON.resources(at: pricePointsPath(territoryID: price.territoryID), via: transport, note: note).data
        let amounts = points.compactMap { point in RetentionJSON.decimal(RetentionJSON.string("customerPrice", of: point)).map { (point, $0) } }
        guard let base = amounts.first(where: { $0.1 == price.amount })?.0["id"] as? String else {
            let sorted = amounts.map(\.1).sorted()
            let nearest = [sorted.last { $0 < price.amount }, sorted.first { $0 > price.amount }].compactMap(\.self)
            throw RetentionPushError.noPricePoint(price: price.amount, nearest: nearest)
        }
        let equalized = try await RetentionJSON.resources(at: equalizationsPath(pricePointID: base), via: transport, note: note).data
        var seen: Set<String> = [price.territoryID]
        var ids = [base]
        for point in equalized {
            guard let territory = RetentionJSON.relatedID("territory", of: point), let id = point["id"] as? String,
                  !seen.contains(territory)
            else { continue }
            seen.insert(territory)
            ids.append(id)
        }
        return ids
    }

    /// Creates the offer with its prices, or finds the one a push made
    /// before; returns its ID.
    @MainActor
    func send(via transport: any PushTransport, note: (AppStoreConnectRateLimit?) -> Void) async throws -> String {
        let full = try await price == nil ? request : request(pricePointIDs: pricePointIDs(via: transport, note: note))
        do {
            let response = try await transport.send(full)
            note(response.rateLimit)
            guard let id = RetentionJSON.resource(in: response.data)?.id else { throw AppStoreConnectError.unexpectedPayload }
            return id
        } catch let refusal as AppStoreConnectError {
            guard NewSubscriptionCreate.mayBeTaken(refusal) else { throw refusal }
            let found = try await RetentionJSON.resources(at: lookupPath, via: transport, note: note)
            guard let id = found.data.first(where: { RetentionJSON.string("offerId", of: $0) == offerID })?["id"] as? String
            else { throw refusal }
            return id
        }
    }
}
