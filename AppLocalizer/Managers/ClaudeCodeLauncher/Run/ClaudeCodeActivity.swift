//
//  ClaudeCodeActivity.swift
//  AppLocalizer
//

import Foundation

/// One line of a run's output, as Show Output lists it: a tool it used,
/// what it said, or something that went wrong.
struct ClaudeCodeActivity: Identifiable, Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case started
        case appLocalizer
        case command
        case file
        case search
        case tool
        case said
        case problem
    }

    var id: Int
    var date: Date
    var kind: Kind
    var text: String
    /// The tool call it describes, so a failed result can mark it.
    var toolUseID: String?

    init(id: Int, date: Date, kind: Kind, text: String, toolUseID: String? = nil) {
        self.id = id
        self.date = date
        self.kind = kind
        self.text = text
        self.toolUseID = toolUseID
    }

    init(id: Int, date: Date, toolUse: ClaudeCodeToolUse) {
        let kind: Kind = switch toolUse.kind {
        case .appLocalizer: .appLocalizer
        case .command: .command
        case .file: .file
        case .search: .search
        case .other: .tool
        }
        self.init(id: id, date: date, kind: kind, text: toolUse.summary, toolUseID: toolUse.id)
    }

    /// The SF Symbol in Show Output's list.
    var systemImage: String {
        switch kind {
        case .started: "play.circle"
        case .appLocalizer: "arrow.right.circle"
        case .command: "terminal"
        case .file: "doc.text"
        case .search: "magnifyingglass"
        case .tool: "wrench.and.screwdriver"
        case .said: "text.bubble"
        case .problem: "exclamationmark.triangle"
        }
    }
}
