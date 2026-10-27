//
//  ListingTransferFormat.swift
//  AppLocalizer
//

import Foundation

/// The file formats for translators: Import & Export → "Export as CSV…".
enum ListingTransferFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    /// One row per field, one column per locale.
    case csv
    /// XLIFF 1.2: the primary locale as source, one `<file>` per target locale.
    case xliff
    /// `{ "locales": { "de-DE": { "subtitle": "…" } } }`.
    case json

    /// Matches a file extension, accepting `xlf` for XLIFF.
    init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "csv": self = .csv
        case "xliff", "xlf": self = .xliff
        case "json": self = .json
        default: return nil
        }
    }

    var id: String { rawValue }

    var fileExtension: String { rawValue }

    var title: String { rawValue.uppercased() }

    /// The menu item, e.g. "Export as CSV…".
    var exportTitle: String { String(localized: "Export as \(title)…") }
}
