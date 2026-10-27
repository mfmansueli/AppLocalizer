//
//  PriceChangeFactory.swift
//  AppLocalizer
//

import Foundation

/// Builds the pending change for one territory's new price: the review
/// row's text, the `POST /v1/subscriptionPrices` that sets it (on the
/// subscription's schedule), the request that puts the old price back, and
/// the check that today's price hasn't changed in App Store Connect since
/// it was read.
struct PriceChangeFactory {
    let appID: StoreApp.ID
    let product: PricingProduct
    /// When the change takes effect; restores always apply at once.
    var schedule = PriceSchedule.immediate

    /// One pending change per subscription and territory, so a new price replaces the queued one.
    static func changeID(productID: String, territoryID: String) -> PendingChange.ID {
        "price.\(productID).\(territoryID)"
    }

    var group: String { String(localized: "Subscription Pricing · \(product.name)") }

    func change(for territory: Territory, from old: PricePoint, to new: PricePoint, source: ChangeSource, at date: Date = .now) -> PendingChange {
        let currency = CurrencyFormat.forCurrency(territory.currencyCode)
        let push = new.appStoreConnectID.flatMap { request(territory: territory, pricePointID: $0, schedule: schedule) }
        let restore = old.appStoreConnectID.flatMap { request(territory: territory, pricePointID: $0, schedule: .immediate) }
        return PendingChange(
            id: Self.changeID(productID: product.id, territoryID: territory.id),
            appID: appID,
            section: .subscriptionPricing,
            group: group,
            groupID: product.id,
            groupNote: schedule.note,
            title: territory.name,
            flagRegion: territory.alpha2,
            oldValue: currency.format(old.customerPrice),
            newValue: currency.format(new.customerPrice),
            deltaPercent: PriceChange(old: old.customerPrice, new: new.customerPrice).percent,
            source: source,
            blockedReason: push == nil ? String(localized: "Apple’s price point for this price isn’t loaded. Refresh, then set it again.") : nil,
            requests: push.map { [$0] } ?? [],
            restoreRequests: restore.map { [$0] } ?? [],
            conflictCheck: conflictCheck(territory: territory, expected: old.customerPrice),
            createdAt: date
        )
    }

    private func request(territory: Territory, pricePointID: String, schedule: PriceSchedule) -> PushRequest? {
        let body = schedule.request(subscriptionID: product.id, territoryID: territory.id, pricePointID: pricePointID)
        return try? PushRequest.json(.post, "/v1/subscriptionPrices", body)
    }

    /// Reads the territory's price right before pushing; a different price
    /// there means someone changed it in App Store Connect meanwhile.
    private func conflictCheck(territory: Territory, expected: Decimal) -> ConflictCheck {
        let query = "filter%5Bterritory%5D=\(territory.id)&include=subscriptionPricePoint"
            + "&fields%5BsubscriptionPricePoints%5D=customerPrice&limit=1"
        return ConflictCheck(
            path: "/v1/subscriptions/\(product.id)/prices?\(query)",
            keyPath: ["included", "0", "attributes", "customerPrice"],
            expected: NSDecimalNumber(decimal: expected).stringValue,
            format: .currency(code: territory.currencyCode, localeIdentifier: territory.localeIdentifier)
        )
    }
}
