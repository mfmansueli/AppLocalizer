//
//  ChangeSource.swift
//  AppLocalizer
//

import Foundation

/// Who or what made a pending change. Review & Push tags every row with it
/// and filters by `filter`; the tag stays neutral (the purple MT color is for
/// unreviewed text, not for this tag).
enum ChangeSource: Hashable, Codable, Sendable {
    /// Typed or picked by the person.
    case you
    /// A price suggestion the person applied ("Recommended").
    case suggestion
    /// A built-in field suggestion the person accepted ("Built-in").
    case builtInSuggestion
    /// A field suggestion from the AI provider in Settings → Translation,
    /// accepted by the person.
    case aiProvider
    /// Accepted machine translation.
    case machineTranslation
    /// Proposed by a connected AI assistant through the MCP server, e.g.
    /// "Claude Code".
    case assistant(client: String)
    /// Queued by "Restore Previous Values" or a Results "Restore".
    case restore

    /// The tag text on a review row.
    var title: String {
        switch self {
        case .you: String(localized: "You")
        case .suggestion: String(localized: "Recommended")
        case .builtInSuggestion: String(localized: "Built-in")
        case .aiProvider: String(localized: "AI provider")
        case .machineTranslation: String(localized: "Machine translation")
        case let .assistant(client): client
        case .restore: String(localized: "Restore")
        }
    }

    /// The review sheet's source filter this change counts under. Applied
    /// suggestions and restores are the person's own decisions; the AI
    /// provider's text counts with machine translation.
    var filter: ChangeSourceFilter {
        switch self {
        case .you, .suggestion, .builtInSuggestion, .restore: .you
        case .machineTranslation, .aiProvider: .machineTranslation
        case let .assistant(client): .assistant(client)
        }
    }

    var isAssistant: Bool {
        if case .assistant = self { return true }
        return false
    }

    /// Two-letter monogram for assistant tags: the initials of a name with
    /// several words ("Claude Code" → "CC"), else its first two letters
    /// ("Cursor" → "CU"). Accepted field suggestions carry their source's:
    /// "AL" for built-in, "AP" for the AI provider.
    var monogram: String? {
        switch self {
        case .builtInSuggestion: return "AL"
        case .aiProvider: return "AP"
        default: break
        }
        guard case let .assistant(client) = self else { return nil }
        let words = client.split(separator: " ")
        let letters = words.count > 1 ? String(words.compactMap(\.first).prefix(2)) : String(client.prefix(2))
        return letters.uppercased()
    }
}
