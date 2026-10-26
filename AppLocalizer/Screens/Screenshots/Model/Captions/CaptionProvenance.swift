//
//  CaptionProvenance.swift
//  AppLocalizer
//

import Foundation

/// Where a caption's text came from. Machine text stays tagged until a
/// person reviews or edits it, and "Proposed by Claude Code · 10:42" stays
/// on an accepted proposal until a person edits it.
enum CaptionProvenance: Codable, Hashable, Sendable {
    /// Written by you; the primary locale's captions are.
    case written
    /// A translation a person changed: the edited dot.
    case edited
    /// Machine text a person marked reviewed, or a human translation.
    case reviewed
    /// Accepted machine translation, not reviewed yet: the MT tag.
    case machineTranslated
    /// Accepted from an assistant's proposal.
    case assistant(client: String, date: Date)

    var isMachineTranslated: Bool { self == .machineTranslated }

    var isEdited: Bool { self == .edited }

    /// The assistant, for the CC tag.
    var assistant: ChangeSource? {
        if case let .assistant(client, _) = self { return .assistant(client: client) }
        return nil
    }

    /// One line for the viewer and the captions editor.
    var title: String {
        switch self {
        case .written: String(localized: "Written by you")
        case .edited: String(localized: "Edited by you")
        case .reviewed: String(localized: "Reviewed")
        case .machineTranslated: String(localized: "Machine translated · not reviewed")
        case let .assistant(client, date):
            String(localized: "Proposed by \(client) · \(date.formatted(date: .omitted, time: .shortened))")
        }
    }
}
