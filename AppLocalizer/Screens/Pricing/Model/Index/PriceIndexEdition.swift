//
//  PriceIndexEdition.swift
//  AppLocalizer
//

import Foundation

/// Which edition of an index the snapshot holds, and how the app labels it.
struct PriceIndexEdition: Hashable, Sendable {
    /// The index picker's edition line, e.g. "January 2026" or
    /// "2024 data, published 2025".
    var label: String
    /// The provenance badge in table rows, e.g. "Big Mac Jan 26".
    var badge: String
    /// The source in breakdown lines, e.g. "× 0.75 (Big Mac, Jan 2026)".
    var provenanceLabel: String
    /// When the edition was published.
    var date: Date
    /// A newer edition the publisher has out, e.g. "July 2026".
    var newerEdition: String?

    /// "Older than a year" in the index picker.
    func isStale(asOf now: Date) -> Bool {
        guard let anniversary = Calendar.gmtGregorian.date(byAdding: .year, value: 1, to: date) else { return false }
        return anniversary < now
    }

    /// "July 2026 available", or nil.
    var newerEditionLabel: String? {
        newerEdition.map { "\($0) available" }
    }
}
