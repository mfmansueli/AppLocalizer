//
//  PriceIncreaseConsent.swift
//  AppLocalizer
//

import Foundation

/// The schedule sheet's warning: the territories whose queued price goes
/// up, with how many existing subscribers each has. Apple tells existing
/// subscribers before an increase, and in some territories (or above
/// Apple's limits) they have to agree or the subscription ends at renewal.
struct PriceIncreaseConsent: Hashable, Sendable {
    struct Item: Hashable, Sendable, Identifiable {
        var territory: Territory
        var oldPrice: Decimal
        var newPrice: Decimal
        /// Nil when AppLocalizer can't read subscriber counts.
        var subscribers: Int?

        var id: String { territory.id }

        var change: PriceChange { PriceChange(old: oldPrice, new: newPrice) }

        /// "₪149.90 → ₪154.90".
        var pricesText: String {
            let currency = CurrencyFormat.forCurrency(territory.currencyCode)
            return currency.format(oldPrice) + " → " + currency.format(newPrice)
        }

        /// "24 subscribers", or nil without counts.
        var subscribersText: String? {
            subscribers.map { $0 == 1 ? String(localized: "1 subscriber") : String(localized: "\($0) subscribers") }
        }
    }

    /// In the matrix's order.
    var items: [Item]

    /// Increases among `rows`' queued prices, counting subscribers from
    /// `subscribers` (by territory ID) when they're known.
    init(rows: [PricingRow], subscribers: [String: Int]?) {
        items = rows.compactMap { row in
            guard let change = row.change, change.direction == .increase else { return nil }
            return Item(territory: row.territory, oldPrice: change.old, newPrice: change.new, subscribers: subscribers.map { $0[row.id] ?? 0 })
        }
    }

    var isEmpty: Bool { items.isEmpty }

    /// Existing subscribers in the territories that go up; nil without counts.
    var subscriberTotal: Int? {
        guard !items.isEmpty, items.allSatisfy({ $0.subscribers != nil }) else { return nil }
        return items.reduce(0) { $0 + ($1.subscribers ?? 0) }
    }

    /// "7 territories go up · 105 existing subscribers".
    var title: String {
        let territories = items.count == 1
            ? String(localized: "1 territory goes up")
            : String(localized: "\(items.count) territories go up")
        guard let total = subscriberTotal else { return territories }
        let people = total == 1 ? String(localized: "1 existing subscriber") : String(localized: "\(total) existing subscribers")
        return territories + " · " + people
    }
}
