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
        case .machineTranslation: String(localized: "Machine translation")
        case let .assistant(client): client
        case .restore: String(localized: "Restore")
        }
    }

    /// The review sheet's source filter this change counts under. Applied
    /// suggestions and restores are the person's own decisions.
    var filter: ChangeSourceFilter {
        switch self {
        case .you, .suggestion, .restore: .you
        case .machineTranslation: .machineTranslation
        case let .assistant(client): .assistant(client)
        }
    }

    var isAssistant: Bool {
        if case .assistant = self { return true }
        return false
    }

    /// Two-letter monogram for assistant tags ("Claude Code" → "CC").
    var monogram: String? {
        guard case let .assistant(client) = self else { return nil }
        let letters = client.split(separator: " ").compactMap(\.first).prefix(2)
        return String(letters).uppercased()
    }
}
