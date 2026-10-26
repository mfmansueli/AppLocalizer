//
//  MCPCallOutcome.swift
//  AppLocalizer
//

import Foundation

/// How an assistant's call ended, as the activity log tags it.
enum MCPCallOutcome: String, Codable, Sendable {
    case read
    case proposed
    case refused

    var title: String {
        switch self {
        case .read: String(localized: "Read")
        case .proposed: String(localized: "Proposed")
        case .refused: String(localized: "Refused")
        }
    }

    var pillStyle: PillStyle {
        switch self {
        case .read: .neutral
        case .proposed: .accent
        case .refused: .warning
        }
    }
}
