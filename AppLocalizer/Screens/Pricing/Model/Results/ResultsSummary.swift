//
//  ResultsSummary.swift
//  AppLocalizer
//

import Foundation

/// The Results cards: totals over the territories with enough data.
struct ResultsSummary: Hashable, Sendable {
    /// Every changed territory.
    var territoryCount: Int
    /// Those with enough data, which the totals cover.
    var countedCount: Int
    var betterCount: Int
    var worseCount: Int
    var tooLittleDataCount: Int
    var startsBefore: Int
    var startsAfter: Int
    var proceedsBefore: Decimal
    var proceedsAfter: Decimal

    /// "+31%".
    var startsChange: PriceChange {
        PriceChange(old: Decimal(startsBefore), new: Decimal(startsAfter))
    }

    /// "−6%".
    var proceedsChange: PriceChange {
        PriceChange(old: proceedsBefore, new: proceedsAfter)
    }

    /// "6 better · 3 worse · 150 too few sales to tell".
    var breakdownText: String {
        String(localized: "\(betterCount) better · \(worseCount) worse · \(tooLittleDataCount) too few sales to tell")
    }
}
