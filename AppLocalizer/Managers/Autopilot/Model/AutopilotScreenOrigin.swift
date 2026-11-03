//
//  AutopilotScreenOrigin.swift
//  AppLocalizer
//

import Foundation

/// Who added a screen to the plan: the person ("Added by you") or the
/// assistant's suggestion the person added ("Suggested by Claude Code").
enum AutopilotScreenOrigin: Codable, Hashable, Sendable {
    case person
    case suggestion(client: String)

    /// "Added by you", "Suggested by Claude Code".
    var tag: String {
        switch self {
        case .person: String(localized: "Added by you")
        case let .suggestion(client): String(localized: "Suggested by \(client)")
        }
    }
}
