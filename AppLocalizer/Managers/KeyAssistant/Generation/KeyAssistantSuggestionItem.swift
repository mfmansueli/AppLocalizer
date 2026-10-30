//
//  KeyAssistantSuggestionItem.swift
//  AppLocalizer
//

import Foundation

/// One suggestion in a model's answer: `{locale, field, value, reason}`,
/// as `suggest_fields` takes them. Store Page checks each like an edit
/// before it shows.
struct KeyAssistantSuggestionItem: Hashable, Decodable, Sendable {
    var locale: String
    var field: String
    var value: String
    var reason: String?
}
