//
//  SuggestionProvenance.swift
//  AppLocalizer
//

import Foundation

/// Who suggested a field's value, kept after it was accepted, for the line
/// under the field ("Accepted Claude Code’s suggestion.") and its Undo. It
/// shows while the field has an unpushed change.
struct SuggestionProvenance: Hashable, Codable, Sendable {
    var suggestionID: FieldSuggestion.ID
    var source: SuggestionSource
    /// The value the suggestion put in the field.
    var value: String
    /// What the field held before, which Undo puts back.
    var previousValue: String
    /// "Use and Edit": the value went in to be edited.
    var isForEditing: Bool

    /// "Accepted Claude Code’s suggestion.", "Using Claude Code’s
    /// suggestion. Edit it above." or, once the text changed, "Edited from
    /// Claude Code’s suggestion."
    func line(currentValue: String) -> String {
        let phrase = source.suggestionPhrase
        if currentValue != value { return String(localized: "Edited from \(phrase).") }
        return isForEditing ? String(localized: "Using \(phrase). Edit it above.") : String(localized: "Accepted \(phrase).")
    }
}
