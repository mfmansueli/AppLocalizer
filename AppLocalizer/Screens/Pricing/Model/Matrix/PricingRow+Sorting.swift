//
//  PricingRow+Sorting.swift
//  AppLocalizer
//

import Foundation

/// The values the matrix sorts by. Money sorts by its approximate dollar
/// value so territories in different currencies compare.
extension PricingRow {
    var regionTitle: String { territory.region.title }

    var currentSortKey: Decimal { dollars ?? 0 }

    var proceedsSortKey: Decimal { ExchangeRates.approximate.dollars(current.proceeds, currency: territory.currencyCode) ?? 0 }

    var equalizedSortKey: Decimal { ExchangeRates.approximate.dollars(equalized, currency: territory.currencyCode) ?? 0 }

    var feelsLikeSortKey: Decimal { recommendation?.feelsLike ?? 0 }

    /// How far the suggestion moves the price, in percent.
    var suggestedSortKey: Int { PriceChange(old: current.customerPrice, new: target.customerPrice).percent }

    var reasonSortKey: String { recommendation?.reason ?? "" }

    var factorSortKey: Decimal { calculation.factor }

    var sourceSortKey: String { calculation.provenance.badge }

    var proposedSortKey: Decimal { ExchangeRates.approximate.dollars(shownPrice, currency: territory.currencyCode) ?? 0 }

    var changeSortKey: Int { change?.percent ?? 0 }

    var statusSortKey: String { status.title }

    /// The default order: where people look most first, then by name (all by
    /// name without sales data).
    static func defaultOrder(_ lhs: PricingRow, _ rhs: PricingRow) -> Bool {
        let left = lhs.pageViews ?? -1
        let right = rhs.pageViews ?? -1
        if left != right { return left > right }
        return lhs.territory.name.localizedStandardCompare(rhs.territory.name) == .orderedAscending
    }
}
