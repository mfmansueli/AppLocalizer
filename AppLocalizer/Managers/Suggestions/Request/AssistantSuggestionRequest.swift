//
//  AssistantSuggestionRequest.swift
//  AppLocalizer
//

import Foundation

/// "Ask Claude Code…": the prompt was copied and AppLocalizer waits for the
/// assistant's suggestions. MCP is driven by the client, so the app can't
/// start it; it can only count what arrives. Over once the assistant goes
/// quiet after sending something, or reaches the total it announced.
struct AssistantSuggestionRequest: Hashable, Sendable {
    var appID: StoreApp.ID
    var area: SuggestionArea
    /// The assistant asked, e.g. "Claude Code".
    var client: String
    /// What was copied, e.g. "Suggest Store Page text for Lumen 1.4…".
    var prompt: String
    var startedAt: Date
    /// Suggestions from `client` for this app since the request began.
    var received = 0
    /// How many the assistant said it would send in all (`suggest_fields`'
    /// `total`), when it said.
    var total: Int?

    /// Something arrived: the popover closes and the banner takes over.
    var isReceiving: Bool { received > 0 }

    var isComplete: Bool {
        guard let total else { return false }
        return received >= total
    }

    /// "Sending suggestions · 2 of 4", or "· 2 so far" without a total.
    var progressText: String {
        if let total { return String(localized: "Sending suggestions · \(received) of \(max(total, received))") }
        return String(localized: "Sending suggestions · \(received) so far")
    }

    /// For the banner's bar; nil without a total.
    var fraction: Double? {
        guard let total, total > 0 else { return nil }
        return min(1, Double(received) / Double(total))
    }

    /// The toast once it's over: "Claude Code sent 4 suggestions. Nothing
    /// changes until you accept them."
    var finishedText: String {
        received == 1
            ? String(localized: "\(client) sent 1 suggestion. Nothing changes until you accept it.")
            : String(localized: "\(client) sent \(received) suggestions. Nothing changes until you accept them.")
    }
}
