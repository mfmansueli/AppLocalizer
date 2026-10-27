//
//  CustomIndexImport.swift
//  AppLocalizer
//

import Foundation

/// What `CustomIndexCSV` read from a file: the import sheet's preview.
struct CustomIndexImport: Hashable, Sendable {
    /// What the CSV's second column holds.
    enum ValueKind: Hashable, Sendable {
        /// A price level relative to the base territory (Brazil 0.55).
        case factor
        /// A local reference price, compared with the base territory's.
        case referencePrice
    }

    /// A line that matched a territory.
    struct Row: Hashable, Sendable {
        var line: Int
        /// The code as written in the file.
        var code: String
        var territory: Territory
        /// The value as written: a factor, or a local price.
        var value: Decimal
        /// The factor the index uses.
        var factor: Decimal
    }

    /// A code that isn't a territory, e.g. `UK` (did you mean GB?).
    struct UnmatchedCode: Hashable, Sendable {
        var line: Int
        var code: String
        /// The territory it most likely means, for common non-ISO codes.
        var suggestion: Territory?
    }

    /// A line that couldn't be read. Line 0 is about the file as a whole.
    struct LineError: Hashable, Sendable {
        var line: Int
        var message: String
    }

    var kind: ValueKind
    var rows: [Row]
    var unmatched: [UnmatchedCode]
    var errors: [LineError]

    /// Matched factors by territory ID.
    var factors: [String: Decimal] {
        Dictionary(rows.map { ($0.territory.id, $0.factor) }, uniquingKeysWith: { first, _ in first })
    }

    /// Whether there's anything to import.
    var isEmpty: Bool { rows.isEmpty }

    /// The import as a custom index for the snapshot, e.g. "Imported
    /// Oct 20, 2026" from `Regional reference prices.csv`.
    func index(fileName: String, importedOn date: Date) -> PriceIndex {
        let edition = PriceIndexEdition(
            label: "Imported " + PricingText.date(date),
            badge: "Custom",
            provenanceLabel: "custom index",
            date: date,
            newerEdition: nil
        )
        return PriceIndex(source: .custom, edition: edition, levels: factors, fileName: fileName)
    }
}
