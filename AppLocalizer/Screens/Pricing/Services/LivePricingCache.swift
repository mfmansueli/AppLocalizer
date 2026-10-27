//
//  LivePricingCache.swift
//  AppLocalizer
//

import Foundation

/// Apple's price point ladders, kept for the session. A ladder takes
/// several requests per territory batch and changes rarely, so each is
/// fetched once per subscription, within the 3,600 requests an hour.
@MainActor
final class LivePricingCache {
    private var ladders: [String: [String: PricePointLadder]] = [:]

    func ladders(for productID: String, territoryIDs: [String]) -> [String: PricePointLadder] {
        let cached = ladders[productID] ?? [:]
        return cached.filter { territoryIDs.contains($0.key) }
    }

    func store(_ newLadders: [String: PricePointLadder], for productID: String) {
        ladders[productID, default: [:]].merge(newLadders) { _, new in new }
    }

    func removeAll() {
        ladders = [:]
    }
}
