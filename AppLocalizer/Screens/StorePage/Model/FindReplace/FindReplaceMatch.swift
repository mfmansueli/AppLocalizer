//
//  FindReplaceMatch.swift
//  AppLocalizer
//

import Foundation

/// A field in a locale that contains the search text, with what it would
/// become. Replacing touches every occurrence in the field.
struct FindReplaceMatch: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    let originalValue: String
    /// Occurrences in `originalValue`, in order.
    let ranges: [Range<String.Index>]
    let replacement: String
    let replacedValue: String

    var id: ListingFieldKey { key }
    var occurrenceCount: Int { ranges.count }

    /// The replaced value checked against the field's rules.
    var validation: ListingFieldValidation {
        ListingFieldValidator.validate(replacedValue, for: key.field)
    }

    /// The replacement would push the field over its limit: flagged in the
    /// preview, and blocked from pushing if applied.
    var isOverLimit: Bool {
        if case .overLimit = validation { return true }
        return false
    }

    /// Context around the first occurrence, before replacing.
    var snippet: FindReplaceSnippet {
        FindReplaceSnippet(text: originalValue, range: ranges[0])
    }

    /// The same context with the replacement highlighted instead.
    var replacedSnippet: FindReplaceSnippet {
        FindReplaceSnippet(text: originalValue, range: ranges[0], highlighted: replacement)
    }
}
