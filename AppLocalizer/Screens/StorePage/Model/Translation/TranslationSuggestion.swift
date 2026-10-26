//
//  TranslationSuggestion.swift
//  AppLocalizer
//

import Foundation

/// A translated text shown against the cell's current text, accepted or
/// rejected per field.
struct TranslationSuggestion: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    /// Usually empty: Translate Missing only fills missing cells.
    let currentText: String
    let suggestedText: String
    var decision: TranslationSuggestionDecision = .pending

    var id: ListingFieldKey { key }

    /// Shown right to left for Arabic and Hebrew, except URLs.
    var isRightToLeft: Bool { key.locale.isRTL && !key.field.isURL }

    /// The suggestion would be over the limit or an invalid URL.
    var validation: ListingFieldValidation {
        ListingFieldValidator.validate(suggestedText, for: key.field)
    }
}
