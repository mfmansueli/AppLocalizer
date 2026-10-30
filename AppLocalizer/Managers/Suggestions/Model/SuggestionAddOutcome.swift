//
//  SuggestionAddOutcome.swift
//  AppLocalizer
//

import Foundation

/// What adding a suggestion did, as `suggest_fields` reports it.
enum SuggestionAddOutcome: String, Hashable, Sendable {
    /// New: it waits under the field.
    case queued
    /// It took the place of an older open suggestion from the same source
    /// for the same field.
    case replaced
    /// The same source already suggested that value and it's still open.
    case unchanged
}
