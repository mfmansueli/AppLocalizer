//
//  ProAssistantGate.swift
//  AppLocalizer
//

import Foundation

/// What an assistant may do over MCP in Free: everything that reads, and
/// every suggestion one by one. A tool that makes something Pro's gets a
/// clear answer that it needs Pro, so the assistant says so and goes on.
enum ProAssistantGate {
    /// The Pro feature a tool belongs to; nil for the tools Free has.
    static func feature(forTool name: String) -> ProFeature? {
        switch name {
        case "propose_retention_message", "propose_retention_offer": .retention
        default: nil
        }
    }

    /// The refusal for `tool` when the person is on Free; nil when it may
    /// run.
    static func refusal(forTool name: String, isPro: Bool) -> String? {
        guard !isPro, let feature = feature(forTool: name) else { return nil }
        return String(localized: """
        \(feature.title) is part of AppLocalizer Pro, and this person is on Free, so this wasn’t queued. Tell them it needs Pro \
        (the Pro button in AppLocalizer’s toolbar) and go on with the rest; reading and one-by-one suggestions work in Free.
        """)
    }
}
