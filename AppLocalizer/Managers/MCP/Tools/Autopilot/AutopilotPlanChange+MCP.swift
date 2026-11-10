//
//  AutopilotPlanChange+MCP.swift
//  AppLocalizer
//

import Foundation

extension AutopilotPlanChange {
    /// What it changes, for the assistant: "steps of Streak", "steps of
    /// Mood (watch)", "sampleData", "writtenFrom", "setupCommands",
    /// "setupNotes".
    var mcpSummary: JSONValue {
        var lines = screens.map { screen in
            screen.displayType.map { "steps of \(screen.name) (\($0.mcpValue))" } ?? "steps of \(screen.name)"
        }
        if sampleData != nil { lines.append("sampleData") }
        if writtenFrom != nil { lines.append("writtenFrom") }
        if setupCommands != nil { lines.append("setupCommands") }
        if setupNotes != nil { lines.append("setupNotes") }
        return .array(lines.map(JSONValue.string))
    }
}
