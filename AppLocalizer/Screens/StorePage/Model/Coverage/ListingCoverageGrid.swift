//
//  ListingCoverageGrid.swift
//  AppLocalizer
//

import Foundation

/// The coverage grid: locales × fields, primary locale first, then by
/// English name, with columns grouped under "App information · all
/// versions" and "Version 1.4".
struct ListingCoverageGrid: Hashable, Sendable {
    let version: ListingVersion
    /// Column order. What's New is left out on a first version.
    let fields: [ListingField]
    let rows: [ListingCoverageRow]
    let summary: ListingCoverageSummary

    init(_ listing: StoreListing) {
        version = listing.version
        fields = listing.fields
        var summary = ListingCoverageSummary()
        summary.localeCount = listing.locales.count
        rows = listing.displayLocales.map { locale in
            let cells = listing.fields.map { field in
                let state = listing.coverageState(of: field, in: locale)
                summary.add(state, hasText: !listing.value(field, in: locale).isEmpty)
                return ListingCoverageCell(key: ListingFieldKey(locale, field), state: state)
            }
            return ListingCoverageRow(locale: locale, isPrimary: locale == listing.primaryLocale, cells: cells)
        }
        self.summary = summary
    }

    /// The columns under one group header.
    func fields(at level: ListingFieldLevel) -> [ListingField] {
        fields.filter { $0.level == level }
    }
}
