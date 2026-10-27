//
//  PricingRow.swift
//  AppLocalizer
//

import Foundation

/// One territory in the price matrix: today's price, what equalization and
/// the strategy would give, the suggestion, and what's queued.
struct PricingRow: Identifiable, Hashable, Sendable {
    var territory: Territory
    var current: PricePoint
    var equalized: Decimal
    var equalizationMultiplier: Decimal
    var isBase: Bool
    /// The suggestion for this territory; nil while Pricing keeps your prices.
    var recommendation: Recommendation?
    /// The price the strategy gives, recommended or custom.
    var calculation: PriceCalculation
    var usesCustomStrategy: Bool
    var pageViews: Int?
    var queued: QueuedPrice?
    /// The subscription's push has a start date, so changes read Scheduled.
    var isScheduled = false

    var id: String { territory.id }

    var currency: CurrencyFormat { CurrencyFormat.forCurrency(territory.currencyCode) }

    // MARK: - Proposal

    /// What “Apply” and following the strategy would set: the custom
    /// strategy's price, else the suggestion. The base territory never moves.
    var target: PricePoint {
        if isBase { return current }
        if usesCustomStrategy { return calculation.price }
        return recommendation?.price ?? current
    }

    var targetOrigin: PriceChangeOrigin { usesCustomStrategy ? .custom : .recommended }

    /// Whether applying would change anything here.
    var hasSuggestion: Bool { Self.differs(target.customerPrice, current.customerPrice) }

    /// The price the Proposed column shows: the queued one, else today's.
    var shownPrice: Decimal { queued?.price ?? current.customerPrice }

    var change: PriceChange? {
        guard let queued, Self.differs(queued.price, current.customerPrice) else { return nil }
        return PriceChange(old: current.customerPrice, new: queued.price)
    }

    var isChanged: Bool { change != nil }

    var origin: PriceChangeOrigin? {
        guard let queued else { return nil }
        return queued.isManual ? .manual : targetOrigin
    }

    var status: PriceChangeStatus {
        PriceChangeStatus.resolve(change: change, origin: origin, isExcluded: calculation.isExcluded, isScheduled: isScheduled)
    }

    // MARK: - Facts

    /// Approximate, from bundled exchange rates.
    var dollars: Decimal? { ExchangeRates.approximate.dollars(current.customerPrice, currency: territory.currencyCode) }

    var isCustomPrice: Bool { Self.differs(current.customerPrice, equalized) }

    var isFallback: Bool { calculation.provenance.isFallback }

    var likelyHeldBack: Bool { recommendation?.likelyHoldsPeopleBack ?? false }

    var pricingText: String { isCustomPrice ? String(localized: "Custom") : String(localized: "Equalized") }

    /// Matches “bra”, “Brazil” or “BRL”.
    func matches(search text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return [territory.name, territory.alpha2, territory.id, territory.currencyCode]
            .contains { $0.localizedStandardContains(query) }
    }

    static func differs(_ lhs: Decimal, _ rhs: Decimal) -> Bool {
        (lhs - rhs).magnitude > Decimal(1) / 1000
    }
}
