//
//  SourceComparison.swift
//  AppLocalizer
//

import Foundation

/// One bar of "Compare sources": what the territory would cost by a source,
/// next to its current and equalized prices.
struct SourceComparison: Hashable, Sendable, Identifiable {
    enum Kind: Hashable, Sendable {
        case current
        case equalized
        case index(PriceIndexSource)
    }

    var kind: Kind
    /// "Current", "Equalized", "Big Mac Index"…
    var title: String
    /// Nil when the source has no data for the territory ("No data").
    var price: Decimal?

    var id: Kind { kind }

    /// "Use this" applies to every bar but Current that has a price.
    var canUse: Bool { kind != .current && price != nil }
}
