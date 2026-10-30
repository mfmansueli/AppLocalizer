//
//  KeyAssistantGenerating.swift
//  AppLocalizer
//

import Foundation

/// A page Generate Suggestions… works on with an API key: what it will
/// send, shown before it does, and a place for what comes back. Only the
/// Store Page is one: App Information's answers come from the code, which
/// a key doesn't read.
@MainActor
protocol KeyAssistantGenerating: AnyObject {
    /// nil until the page has loaded.
    func keyAssistantPlan(using keyAssistant: KeyAssistantController) async -> KeyAssistantPlan?

    /// Checks each suggestion like an edit, adds those that pass from
    /// `client`, and returns how many were new.
    func addGeneratedSuggestions(_ items: [KeyAssistantSuggestionItem], client: String) -> Int
}
