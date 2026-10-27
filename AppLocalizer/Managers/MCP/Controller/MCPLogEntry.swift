//
//  MCPLogEntry.swift
//  AppLocalizer
//

import Foundation

/// One line of Settings → AI Assistants → Activity log: who called which
/// tool about what, and whether it was read, proposed or refused (and why).
struct MCPLogEntry: Identifiable, Hashable, Sendable {
    var id = UUID()
    var date: Date
    /// e.g. "Claude Code".
    var client: String
    /// e.g. "propose_listing_text".
    var tool: String
    /// e.g. "Lumen Journal · de-DE · Subtitle".
    var target: String
    var outcome: MCPCallOutcome
    /// Why it was refused, as the assistant was told.
    var reason: String?
}
