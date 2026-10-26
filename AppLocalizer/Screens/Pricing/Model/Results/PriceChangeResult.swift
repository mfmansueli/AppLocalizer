//
//  PriceChangeResult.swift
//  AppLocalizer
//

import Foundation

/// A territory's 28 days before and after a pushed price change.
struct PriceChangeResult: Hashable, Sendable, Identifiable {
    var territory: Territory
    var oldPrice: Decimal
    var newPrice: Decimal
    var before: SalesWindow
    var after: SalesWindow

    var id: String { territory.id }

    var verdict: ResultVerdict {
        ResultsEvaluator.verdict(before: before, after: after)
    }

    var priceChange: PriceChange {
        PriceChange(old: oldPrice, new: newPrice)
    }

    /// Starts change, e.g. +119%; nil without starts before.
    var startsChange: PriceChange? {
        before.starts > 0 ? PriceChange(old: Decimal(before.starts), new: Decimal(after.starts)) : nil
    }
}
