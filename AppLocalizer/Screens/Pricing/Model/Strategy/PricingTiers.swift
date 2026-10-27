//
//  PricingTiers.swift
//  AppLocalizer
//

import Foundation

/// Optional tiers: territories bucketed by factor so similar markets get the
/// same discount. Tier 1 is factor ≥ 0.85 at 100%, down to tier 4 below
/// 0.45 at 40%.
struct PricingTiers: Hashable, Sendable, Codable {
    /// Lower bounds of tiers 1–3, descending: [0.85, 0.65, 0.45].
    var thresholds: [Decimal]
    /// Factor applied in tiers 1–4: [1.0, 0.8, 0.6, 0.4].
    var shares: [Decimal]

    static let standard = PricingTiers(
        thresholds: [Decimal(85) / 100, Decimal(65) / 100, Decimal(45) / 100],
        shares: [1, Decimal(8) / 10, Decimal(6) / 10, Decimal(4) / 10]
    )

    /// 0-based tier for a factor: 0 when it clears the first threshold.
    func tierIndex(for factor: Decimal) -> Int {
        thresholds.firstIndex { factor >= $0 } ?? thresholds.count
    }

    /// The factor a tier applies, e.g. 0.8 for the second.
    func share(forTier index: Int) -> Decimal {
        shares.indices.contains(index) ? shares[index] : 1
    }

    /// The inspector's rule: "factor ≥ 0.85", "0.65–0.85", "below 0.45".
    func rule(forTier index: Int) -> String {
        guard !thresholds.isEmpty else { return "" }
        if index == 0 { return "factor ≥ " + thresholds[0].trimmed(maxPlaces: 2) }
        if index >= thresholds.count { return "below " + thresholds[thresholds.count - 1].trimmed(maxPlaces: 2) }
        return thresholds[index].trimmed(maxPlaces: 2) + "–" + thresholds[index - 1].trimmed(maxPlaces: 2)
    }
}
