//
//  SuggestionPrompt.swift
//  AppLocalizer
//

import Foundation

/// What "Ask Claude Code…" copies for the person to paste into their
/// assistant. AppLocalizer can't start the assistant; the MCP prompt
/// `suggest` (`/mcp__applocalizer__suggest`) asks the same.
enum SuggestionPrompt {
    /// "Suggest Store Page text for Lumen 1.4 in AppLocalizer: What’s New,
    /// promotional text and subtitle, in English and in every language that
    /// has a translation."
    static func text(for area: SuggestionArea, app: String, version: String?, primaryLanguage: String? = nil) -> String {
        let subject = [app, version].compactMap(\.self).joined(separator: " ")
        switch area {
        case .storePage:
            let primary = primaryLanguage ?? String(localized: "the primary language")
            return String(localized: """
            Suggest Store Page text for \(subject) in AppLocalizer: What’s New, promotional text and subtitle, in \
            \(primary) and in every language that has a translation.
            """)
        case .appInformation:
            return String(localized: """
            Suggest App Information and App Review details for \(subject) in AppLocalizer, from the code, and App \
            Review's contact if it's empty.
            """)
        }
    }
}
