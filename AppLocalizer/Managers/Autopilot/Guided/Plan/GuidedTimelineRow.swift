//
//  GuidedTimelineRow.swift
//  AppLocalizer
//

import Foundation

/// A line of the guided plan: who does what, what it means, and how long
/// it takes or which stop it is.
struct GuidedTimelineRow: Hashable, Sendable, Identifiable {
    enum Who: Hashable, Sendable {
        /// "Claude Code".
        case assistant(String)
        /// "Claude Design", or AppLocalizer's starters.
        case designer(String)
        case appLocalizer
        case you

        var name: String {
            switch self {
            case let .assistant(name), let .designer(name): name
            case .appLocalizer: "AppLocalizer"
            case .you: String(localized: "You")
            }
        }

        /// "CC", "CD", "AL": the badge's initials.
        var initials: String {
            switch self {
            case .you: ""
            case .appLocalizer: "AL"
            case let .assistant(name), let .designer(name):
                String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
            }
        }
    }

    enum Kind: String, Hashable, Sendable {
        case capture
        case pick
        case design
        case choose
        case localize
        case review
    }

    var kind: Kind
    var who: Who
    var title: String
    var detail: String
    /// "about 12 min", "stop 1 of 2", "the only stop".
    var time: String

    var id: Kind { kind }
    var isYours: Bool { who == .you }
}
