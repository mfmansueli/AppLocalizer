//
//  PriceCalculation.swift
//  AppLocalizer
//

import Foundation

/// A proposed price and how it was reached, for the table and the breakdown
/// popover.
struct PriceCalculation: Hashable, Sendable {
    /// The final price point.
    var price: PricePoint
    var equalizedPrice: Decimal
    /// Equalized × multiplier, before the floor and other limits.
    var target: Decimal
    /// 1 − intensity + intensity × factor (or the region multiplier).
    var multiplier: Decimal
    var factor: Decimal
    /// 1-based tier when tiers are on.
    var tier: Int?
    var provenance: PriceProvenance
    var adjustment: PriceAdjustment
    /// One line: "R$ 219,90 equalized × 0.5 = R$ 109,95 → above floor →
    /// R$ 109,90".
    var summary: String
    /// The numbered steps of the breakdown popover.
    var steps: [String]

    var isExcluded: Bool { provenance.kind == .excluded }

    /// The tier chip: "T2".
    var tierLabel: String? { tier.map { "T\($0)" } }
}
