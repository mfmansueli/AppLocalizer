//
//  PriceMatrixFilter.swift
//  AppLocalizer
//

import Foundation

/// The matrix's filters: a region, three toggles and a search by territory,
/// code or currency. Each narrows the rows further.
struct PriceMatrixFilter: Hashable, Sendable {
    var region: TerritoryRegion?
    var changedOnly = false
    var increasesOnly = false
    var fallbackOnly = false
    var searchText = ""

    var isActive: Bool {
        region != nil || changedOnly || increasesOnly || fallbackOnly || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func matches(_ row: PricingRow) -> Bool {
        if let region, row.territory.region != region { return false }
        if changedOnly, !row.isChanged { return false }
        if increasesOnly, row.change?.direction != .increase { return false }
        if fallbackOnly, !row.isFallback { return false }
        return row.matches(search: searchText)
    }
}
