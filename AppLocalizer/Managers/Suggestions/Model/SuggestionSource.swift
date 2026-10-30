//
//  SuggestionSource.swift
//  AppLocalizer
//

import Foundation

/// Where a field suggestion came from. Its tag stays neutral: the purple
/// "Suggested" pill is what says a value isn't reviewed yet.
enum SuggestionSource: Hashable, Codable, Sendable {
    /// AppLocalizer's own checks: limits, words repeated between name,
    /// subtitle and keywords, empty fields other languages fill, dates and
    /// the previous version's values. Always on.
    case builtIn
    /// A connected assistant, over MCP (`suggest_fields`), e.g. "Claude Code".
    case assistant(client: String)
    /// The AI provider whose key is in Settings → Translation.
    case aiProvider

    /// The tag's name: "Built-in", "Claude Code", "AI provider".
    var title: String {
        switch self {
        case .builtIn: String(localized: "Built-in")
        case let .assistant(client): client
        case .aiProvider: String(localized: "AI provider")
        }
    }

    /// The tag's two letters: "AL" for AppLocalizer's own checks, the
    /// assistant's ("CC"), "AP" for the AI provider.
    var monogram: String {
        switch self {
        case .builtIn: "AL"
        case let .assistant(client): ChangeSource.assistant(client: client).monogram ?? "AI"
        case .aiProvider: "AP"
        }
    }

    /// As in "Accepted Claude Code’s suggestion.": "Claude Code’s
    /// suggestion", "a built-in suggestion", "the AI provider’s suggestion".
    var suggestionPhrase: String {
        switch self {
        case .builtIn: String(localized: "a built-in suggestion")
        case let .assistant(client): String(localized: "\(client)’s suggestion")
        case .aiProvider: String(localized: "the AI provider’s suggestion")
        }
    }

    /// Who an accepted suggestion's change is tagged with in Review & Push.
    var changeSource: ChangeSource {
        switch self {
        case .builtIn: .builtInSuggestion
        case let .assistant(client): .assistant(client: client)
        case .aiProvider: .aiProvider
        }
    }

    /// The suggestion bar's segment it counts under.
    var filter: SuggestionSourceFilter {
        switch self {
        case .builtIn: .builtIn
        case .assistant: .assistant
        case .aiProvider: .aiProvider
        }
    }

    var isAssistant: Bool { assistantName != nil }

    /// The assistant's name, e.g. "Claude Code"; nil for the others.
    var assistantName: String? {
        if case let .assistant(client) = self { return client }
        return nil
    }
}
