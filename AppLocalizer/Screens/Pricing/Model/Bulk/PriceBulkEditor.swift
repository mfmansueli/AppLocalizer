//
//  PriceBulkEditor.swift
//  AppLocalizer
//

import Foundation

/// The bottom bar's bulk actions. Each returns the new price per territory
/// ID, always on a price point; the caller records them as manual edits.
enum PriceBulkEditor {
    /// Multiply by 0.9 / 0.8 / 1.1: the shown price × factor, snapped.
    static func multiply(_ rows: [PriceBulkRow], by factor: Decimal, rounding: PriceRounding) -> [String: PricePoint] {
        snapped(rows, rounding: rounding) { $0.shownPrice * factor }
    }

    /// "Set to Feel Like $39.99": the price that feels like the base price
    /// locally, base × equalization multiplier × feels-like factor.
    static func feelLikeBase(_ rows: [PriceBulkRow], basePrice: Decimal, rounding: PriceRounding) -> [String: PricePoint] {
        snapped(rows, rounding: rounding) { basePrice * $0.equalizationMultiplier * $0.feelsLikeFactor }
    }

    /// Reset to Equalized: Apple's equalized price.
    static func resetToEqualized(_ rows: [PriceBulkRow]) -> [String: PricePoint] {
        var prices: [String: PricePoint] = [:]
        for row in rows {
            prices[row.territory.id] = row.ladder.point(at: row.equalizedPrice) ?? row.ladder.nearest(to: row.equalizedPrice)
        }
        return prices
    }

    /// "Copy from Monthly × 8.0": another subscription's price in the same
    /// territory × ratio, snapped. Territories missing from `prices` are left
    /// out.
    static func copy(
        _ rows: [PriceBulkRow],
        from prices: [String: Decimal],
        ratio: Decimal,
        rounding: PriceRounding
    ) -> [String: PricePoint] {
        snapped(rows.filter { prices[$0.territory.id] != nil }, rounding: rounding) { prices[$0.territory.id, default: 0] * ratio }
    }

    /// Apply to the whole group, keeping the duration ratio: each territory's
    /// price for this subscription = the anchor subscription's price there ×
    /// (this base price ÷ the anchor's base price), so Annual stays 8.0×
    /// Monthly everywhere.
    static func keepingDurationRatio(
        _ rows: [PriceBulkRow],
        anchorPrices: [String: Decimal],
        anchorBasePrice: Decimal,
        basePrice: Decimal,
        rounding: PriceRounding
    ) -> [String: PricePoint] {
        guard anchorBasePrice > 0 else { return [:] }
        return copy(rows, from: anchorPrices, ratio: basePrice / anchorBasePrice, rounding: rounding)
    }

    /// The ratio between two base prices, to one decimal for the menu title:
    /// $39.99 ÷ $4.99 → "8.0".
    static func durationRatioText(_ basePrice: Decimal, over otherBasePrice: Decimal) -> String {
        guard otherBasePrice > 0 else { return "" }
        return (basePrice / otherBasePrice).fixed(1)
    }

    private static func snapped(
        _ rows: [PriceBulkRow],
        rounding: PriceRounding,
        target: (PriceBulkRow) -> Decimal
    ) -> [String: PricePoint] {
        var prices: [String: PricePoint] = [:]
        for row in rows {
            prices[row.territory.id] = row.ladder.nearest(to: target(row), rounding: rounding)
        }
        return prices
    }
}
