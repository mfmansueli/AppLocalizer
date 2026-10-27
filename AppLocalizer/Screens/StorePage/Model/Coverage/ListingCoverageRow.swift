//
//  ListingCoverageRow.swift
//  AppLocalizer
//

import Foundation

/// One locale's row of the coverage grid, cells in column order.
struct ListingCoverageRow: Identifiable, Hashable, Sendable {
    let locale: StoreLocale
    /// Tagged "Primary"; its What's New is the source for every other locale.
    let isPrimary: Bool
    let cells: [ListingCoverageCell]

    var id: StoreLocale { locale }
}
