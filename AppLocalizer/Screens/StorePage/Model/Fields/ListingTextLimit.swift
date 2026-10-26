//
//  ListingTextLimit.swift
//  AppLocalizer
//

import Foundation

/// A field's maximum length, in characters or (for keywords) UTF-8 bytes.
struct ListingTextLimit: Hashable, Sendable {
    let maximum: Int
    let unit: ListingLimitUnit

    init(_ maximum: Int, unit: ListingLimitUnit = .characters) {
        self.maximum = maximum
        self.unit = unit
    }

    /// The text's length in this limit's unit.
    func count(_ text: String) -> Int {
        unit.count(text)
    }

    func isExceeded(by text: String) -> Bool {
        count(text) > maximum
    }
}
