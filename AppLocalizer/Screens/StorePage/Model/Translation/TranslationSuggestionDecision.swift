//
//  TranslationSuggestionDecision.swift
//  AppLocalizer
//

import Foundation

/// What you decided about one translation suggestion.
enum TranslationSuggestionDecision: Hashable, Sendable {
    case pending
    case accepted
    case rejected
}
