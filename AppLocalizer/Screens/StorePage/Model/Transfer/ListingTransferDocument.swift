//
//  ListingTransferDocument.swift
//  AppLocalizer
//

import Foundation

/// The contents of an imported CSV, XLIFF or JSON file, before it's
/// compared with the listing (`ListingImportPreview`).
struct ListingTransferDocument: Hashable, Sendable {
    let format: ListingTransferFormat
    /// What the file says it's for, when it says.
    var appName: String?
    var version: String?
    var sourceLocaleCode: String?
    /// In file order. Empty values mean "not translated" and never clear a field.
    var entries: [ListingTransferEntry]
}
