//
//  ListingLimitUnit.swift
//  AppLocalizer
//

import Foundation

/// What a limit counts. Only keywords are limited in bytes.
enum ListingLimitUnit: Hashable, Sendable {
    case characters
    case bytes

    func count(_ text: String) -> Int {
        switch self {
        case .characters: ListingTextMeasure.characters(in: text)
        case .bytes: ListingTextMeasure.utf8Bytes(in: text)
        }
    }

    /// "characters" or "bytes", for messages like "31 of 30 characters".
    var name: String {
        switch self {
        case .characters: String(localized: "characters")
        case .bytes: String(localized: "bytes")
        }
    }
}
