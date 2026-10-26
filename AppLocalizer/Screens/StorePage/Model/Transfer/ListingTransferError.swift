//
//  ListingTransferError.swift
//  AppLocalizer
//

import Foundation

/// Why an imported file couldn't be read at all. Problems with single
/// values are `ListingImportProblem`s instead.
enum ListingTransferError: LocalizedError, Hashable, Sendable {
    case unsupportedFileType(String)
    /// Not UTF-8 text.
    case notText
    /// A CSV without a "field" column.
    case missingFieldColumn
    /// Malformed XML or JSON, with the parser's detail if any.
    case unreadable(detail: String?)

    var errorDescription: String? {
        switch self {
        case let .unsupportedFileType(fileExtension):
            String(localized: "“.\(fileExtension)” files can’t be imported. Choose a CSV, XLIFF or JSON file.")
        case .notText:
            String(localized: "The file isn’t UTF-8 text.")
        case .missingFieldColumn:
            String(localized: "The CSV needs a “field” column with field names like subtitle or whatsNew.")
        case let .unreadable(detail):
            if let detail {
                String(localized: "The file couldn’t be read: \(detail)")
            } else {
                String(localized: "The file couldn’t be read.")
            }
        }
    }
}
