//
//  InAppTextsAskPrompt.swift
//  AppLocalizer
//

import Foundation

/// What "Ask Claude Code…" on In-App Texts starts Claude Code with, or
/// copies: fill the missing group, subscription and in-app purchase texts
/// with `get_in_app_texts` and `propose_in_app_texts`.
enum InAppTextsAskPrompt {
    /// The run's purpose, so the button finds its own run.
    static var purpose: ClaudeCodeRunPurpose { .ask(area: String(localized: "In-App Texts")) }

    /// "Suggest In-App Texts for Alba: Daily Motivation in AppLocalizer: …".
    static func text(app: String) -> String {
        String(localized: """
        Suggest In-App Texts for \(app) in AppLocalizer: the subscription group's display name, and each \
        subscription's and in-app purchase's display name and description, in every language of its Store Page \
        where one is missing. Read them with get_in_app_texts, write in each language and within the limits, and \
        propose them with propose_in_app_texts. Leave texts that are already there as they are.
        """)
    }
}
