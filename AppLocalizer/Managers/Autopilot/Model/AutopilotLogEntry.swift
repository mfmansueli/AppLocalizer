//
//  AutopilotLogEntry.swift
//  AppLocalizer
//

import Foundation

/// One line of the run's log: what the assistant ran or what happened.
struct AutopilotLogEntry: Codable, Hashable, Sendable, Identifiable {
    enum Kind: String, Codable, Hashable, Sendable {
        /// A command or step the assistant ran, drawn dimmed.
        case command
        /// Something that arrived, drawn in the label color.
        case event
        /// A problem, drawn in red.
        case problem
    }

    var id: UUID = .init()
    var date: Date
    var text: String
    var kind: Kind
}
