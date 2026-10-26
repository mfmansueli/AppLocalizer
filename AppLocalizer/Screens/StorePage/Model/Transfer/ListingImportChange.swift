//
//  ListingImportChange.swift
//  AppLocalizer
//

import Foundation

/// One row of the import diff: a field the file would change, old struck
/// through above new, with a checkbox (on by default).
struct ListingImportChange: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    /// The current value on this Mac; empty shows as "Empty".
    let oldValue: String
    let newValue: String
    var isSelected = true

    var id: ListingFieldKey { key }
}
