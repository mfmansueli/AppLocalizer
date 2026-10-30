//
//  SuggestionSourceFilter.swift
//  AppLocalizer
//

import Foundation

/// The suggestion bar's "Show suggestions from" control: All · Built-in ·
/// the assistant · AI provider. Sources with nothing open are hidden, except
/// All and the assistant, whose segment says what connecting adds.
enum SuggestionSourceFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case builtIn
    case assistant
    case aiProvider

    var id: Self { self }

    /// The segment's name; the assistant's is the connected client's, e.g.
    /// "Claude Code", or "Assistant" before one is set up.
    func title(assistant: String?) -> String {
        switch self {
        case .all: String(localized: "All")
        case .builtIn: String(localized: "Built-in")
        case .assistant: assistant ?? String(localized: "Assistant")
        case .aiProvider: String(localized: "AI provider")
        }
    }

    func includes(_ source: SuggestionSource) -> Bool {
        self == .all || source.filter == self
    }
}
