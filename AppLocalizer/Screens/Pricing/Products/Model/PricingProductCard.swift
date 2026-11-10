//
//  PricingProductCard.swift
//  AppLocalizer
//

import Foundation

/// One product on Pricing's Prices page: its price in the base territory,
/// how its prices are set (equalized, custom, suggested, not pushed), the
/// open price suggestion with the countries it changes, and each country's
/// price for "What people pay".
struct PricingProductCard: Identifiable, Equatable, Sendable {
    /// The open suggestion: every territory whose strategy price differs
    /// from today's and that nothing is queued for yet.
    struct Suggestion: Equatable, Sendable {
        /// "Lower the price in 104 countries and regions".
        var title: String
        var reason: String
        var count: Int
        /// The countries the table lists, most visited first.
        var countries: [Country]
        /// "and 96 more countries and regions".
        var moreCount: Int
    }

    struct Country: Identifiable, Equatable, Sendable {
        /// Alpha-3.
        var id: String
        var name: String
        var now: String
        var suggested: String
        /// "−25%", "+12%".
        var change: String
    }

    /// A country's price now, and the next one: what's queued, else the
    /// open suggestion.
    struct TerritoryPrice: Equatable, Sendable {
        var now: String
        var next: String?
    }

    var product: PricingProduct
    /// "$39.99".
    var basePrice: String?
    /// "in the United States".
    var baseTerritoryText: String
    var territoryCount: Int
    var equalizedCount: Int
    var customCount: Int
    var suggestedCount: Int
    var queuedCount: Int
    var suggestion: Suggestion?
    /// By alpha-3.
    var prices: [String: TerritoryPrice]

    var id: String { product.id }

    var hasQueuedChanges: Bool { queuedCount > 0 }

    /// "Subscription · 1 year", "Non-consumable".
    var kindText: String {
        guard !product.isInAppPurchase else { return product.durationText }
        return String(localized: "Subscription · \(product.durationText)")
    }

    /// "175 countries and regions · 71 equalized · 104 suggested".
    var legend: String {
        var parts = [territoryCount == 1 ? String(localized: "1 country or region") : String(localized: "\(territoryCount) countries and regions")]
        if equalizedCount > 0 { parts.append(String(localized: "\(equalizedCount) equalized")) }
        if customCount > 0 { parts.append(String(localized: "\(customCount) custom")) }
        if suggestedCount > 0 { parts.append(String(localized: "\(suggestedCount) suggested")) }
        if queuedCount > 0 { parts.append(String(localized: "\(queuedCount) not pushed")) }
        return parts.joined(separator: " · ")
    }

    /// How many countries the table lists before "and n more".
    static let listedCountryCount = 8

    /// Reads the card from the product's matrix rows. A dismissed
    /// suggestion, Keep my prices and in-app purchases show none.
    static func make(product: PricingProduct, rows: [PricingRow], showsSuggestions: Bool, isDismissed: Bool) -> PricingProductCard {
        let base = rows.first(where: \.isBase)
        let isOpen: (PricingRow) -> Bool = { row in
            showsSuggestions && !isDismissed && !row.isBase && row.queued == nil && row.hasSuggestion
        }
        var equalized = 0, custom = 0, suggested = 0, queued = 0
        var prices: [String: TerritoryPrice] = [:]
        for row in rows {
            if row.isChanged {
                queued += 1
            } else if isOpen(row) {
                suggested += 1
            } else if row.isCustomPrice {
                custom += 1
            } else {
                equalized += 1
            }
            let next: Decimal? = row.isChanged ? row.shownPrice : isOpen(row) ? row.target.customerPrice : nil
            prices[row.id] = TerritoryPrice(now: row.currency.format(row.current.customerPrice), next: next.map(row.currency.format))
        }
        let open = rows.filter(isOpen)
        return PricingProductCard(
            product: product,
            basePrice: base.map { $0.currency.format($0.shownPrice) } ?? product.basePriceText,
            baseTerritoryText: base.map { territoryText($0.territory) } ?? String(localized: "in the United States"),
            territoryCount: rows.count,
            equalizedCount: equalized,
            customCount: custom,
            suggestedCount: suggested,
            queuedCount: queued,
            suggestion: open.isEmpty ? nil : makeSuggestion(for: open, base: base),
            prices: prices
        )
    }

    /// "in the United States", "in Germany".
    static func territoryText(_ territory: Territory) -> String {
        territory.alpha2 == "US" ? String(localized: "in the United States") : String(localized: "in \(territory.name)")
    }

    private static func makeSuggestion(for rows: [PricingRow], base: PricingRow?) -> Suggestion {
        let lower = rows.count { $0.target.customerPrice < $0.current.customerPrice }
        let higher = rows.count - lower
        let places = rows.count == 1 ? String(localized: "1 country or region") : String(localized: "\(rows.count) countries and regions")
        let title = switch (lower, higher) {
        case (_, 0): String(localized: "Lower the price in \(places)")
        case (0, _): String(localized: "Raise the price in \(places)")
        default: String(localized: "New prices in \(places): \(lower) lower, \(higher) higher")
        }
        let listed = rows.sorted { lhs, rhs in
            let left = lhs.pageViews ?? 0, right = rhs.pageViews ?? 0
            return left == right ? lhs.territory.name < rhs.territory.name : left > right
        }
        .prefix(listedCountryCount)
        return Suggestion(
            title: title,
            reason: reason(for: rows, base: base),
            count: rows.count,
            countries: listed.map(country),
            moreCount: max(0, rows.count - listedCountryCount)
        )
    }

    private static func reason(for rows: [PricingRow], base: PricingRow?) -> String {
        let heldBack = rows.count(where: \.likelyHeldBack)
        let baseName = base.map { $0.territory.alpha2 == "US" ? String(localized: "the United States") : $0.territory.name }
            ?? String(localized: "the United States")
        if heldBack > 0 {
            return heldBack == 1
                ? String(localized: "In 1 of them the price feels at least 25% higher than in \(baseName), which likely holds people back.")
                : String(localized: "In \(heldBack) of them the price feels at least 25% higher than in \(baseName), which likely holds people back.")
        }
        if let first = rows.first(where: { $0.recommendation?.reason.isEmpty == false }), let reason = first.recommendation?.reason {
            return "\(first.territory.name): \(reason)"
        }
        return String(localized: "They follow the pricing strategy in Customize….")
    }

    private static func country(_ row: PricingRow) -> Country {
        let now = row.current.customerPrice
        let next = row.target.customerPrice
        let percent = now == 0 ? 0 : NSDecimalNumber(decimal: (next - now) / now * 100).doubleValue.rounded()
        let change = percent < 0 ? "−\(Int(-percent))%" : "+\(Int(percent))%"
        return Country(id: row.id, name: row.territory.name, now: row.currency.format(now), suggested: row.currency.format(next), change: change)
    }
}
