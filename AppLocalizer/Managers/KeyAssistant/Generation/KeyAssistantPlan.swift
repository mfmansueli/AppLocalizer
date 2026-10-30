//
//  KeyAssistantPlan.swift
//  AppLocalizer
//

import Foundation

/// What Generate Suggestions… will send, shown before it does: each part
/// with about how many tokens it is, the prompt itself, and anything that
/// couldn't be read.
struct KeyAssistantPlan: Hashable, Sendable {
    /// Recent Requests' line: "Store Page · English, German".
    var title: String
    var items: [KeyAssistantSendItem]
    var system: String
    var user: String
    /// e.g. "The project folder can’t be found…".
    var notes: [String] = []

    var totalTokens: Int {
        KeyAssistantTokens.estimate(system) + KeyAssistantTokens.estimate(user)
    }

    /// "About 9.4k tokens in, billed to your Anthropic account. Source code
    /// isn’t sent."
    func totalText(vendor: AIProviderVendor) -> String {
        String(localized: "About \(KeyAssistantTokens.formatted(totalTokens)) tokens in, billed to your \(vendor.title) account. Source code isn’t sent.")
    }
}
