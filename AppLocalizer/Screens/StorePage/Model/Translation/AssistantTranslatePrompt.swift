//
//  AssistantTranslatePrompt.swift
//  AppLocalizer
//

import Foundation

/// What the person pastes into their assistant to translate the missing
/// fields, since AppLocalizer can't start it: Claude Code's slash command for
/// the server's `translate_missing` prompt, and the same request in words
/// for any other MCP client, with the glossary and tone.
struct AssistantTranslatePrompt: Hashable, Sendable {
    let appName: String
    let versionString: String
    let glossary: TranslationGlossary

    /// "/mcp__applocalizer__translate_missing Lumen Journal".
    var slashCommand: String {
        "\(MCPPrompt.translateMissing.slashCommand) \(appName)"
    }

    /// "Use AppLocalizer to translate the missing store-page fields for Lumen
    /// Journal 1.4. Keep “Lumen” and “Face ID” untranslated and keep the tone
    /// warm and simple. Propose each field; I’ll review in AppLocalizer."
    var text: String {
        let tone = glossary.tone.promptPhrase
        let keep = if glossary.terms.isEmpty {
            "Keep the tone \(tone)."
        } else {
            "Keep \(glossary.terms.map { "“\($0)”" }.formatted(.list(type: .and).locale(Locale(identifier: "en")))) untranslated "
                + "and keep the tone \(tone)."
        }
        return "Use AppLocalizer to translate the missing store-page fields for \(appName) \(versionString). \(keep) "
            + "Propose each field; I’ll review in AppLocalizer."
    }
}
