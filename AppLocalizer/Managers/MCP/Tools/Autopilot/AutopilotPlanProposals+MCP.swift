//
//  AutopilotPlanProposals+MCP.swift
//  AppLocalizer
//

import Foundation

/// What waits for the app's next plan, as `get_capture_plan` gives it, so
/// the assistant doesn't send it again.
extension AutopilotPlanProposals {
    /// `queuedForNextPlan`: each change and each batch of screens still
    /// open, oldest first; nil when nothing waits.
    var mcpJSON: JSONValue? {
        let changes: [JSONValue] = changes.map { change in
            [
                "proposalId": .string(change.id), "kind": "changes", "client": .string(change.client),
                "receivedAt": .string(change.receivedAt.formatted(.iso8601)), "waiting": change.mcpSummary,
            ]
        }
        let screens: [JSONValue] = screens.filter { !$0.open.isEmpty }.map { batch in
            [
                "proposalId": .string(batch.id ?? ""), "kind": "screens", "client": .string(batch.client),
                "receivedAt": .string(batch.receivedAt.formatted(.iso8601)),
                "device": .string(batch.device == .watch ? "watch" : "set"),
                "screens": .array(batch.open.map { .string($0.name) }),
            ]
        }
        let all = changes + screens
        return all.isEmpty ? nil : .array(all)
    }
}
