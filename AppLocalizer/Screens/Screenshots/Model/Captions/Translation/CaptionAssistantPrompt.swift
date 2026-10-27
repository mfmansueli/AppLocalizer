//
//  CaptionAssistantPrompt.swift
//  AppLocalizer
//

import Foundation

/// What the person pastes into their assistant to fill the empty captions,
/// since AppLocalizer can't start it: Claude Code's slash command for the
/// server's `translate_captions` prompt, and the same request in words for
/// any other MCP client, with the glossary and tone. The assistant measures
/// each caption and proposes it; nothing is written until it's accepted.
struct CaptionAssistantPrompt: Hashable, Sendable {
    /// The MCP prompt's name (design README §5).
    static let promptName = "translate_captions"

    let appName: String
    let versionString: String
    let glossary: TranslationGlossary

    /// "/mcp__applocalizer__translate_captions Lumen Journal".
    var slashCommand: String {
        "/mcp__\(MCPEndpoint.serverName)__\(Self.promptName) \(appName)"
    }

    /// "Use AppLocalizer to translate the empty screenshot captions for
    /// Lumen Journal 1.4. Keep “Lumen” untranslated and keep the tone warm
    /// and simple. Measure each caption so it fits, and propose it; I’ll
    /// review in AppLocalizer."
    var text: String {
        let tone = glossary.tone.promptPhrase
        let keep = if glossary.terms.isEmpty {
            "Keep the tone \(tone)."
        } else {
            "Keep \(glossary.terms.map { "“\($0)”" }.formatted(.list(type: .and).locale(Locale(identifier: "en")))) untranslated "
                + "and keep the tone \(tone)."
        }
        return "Use AppLocalizer to translate the empty screenshot captions for \(appName) \(versionString). \(keep) "
            + "Measure each caption so it fits, and propose it; I’ll review in AppLocalizer."
    }
}
