//
//  AssistantTranslatePromptTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("AssistantTranslatePrompt")
struct AssistantTranslatePromptTests {
    @Test func theSlashCommandNamesTheApp() {
        let prompt = AssistantTranslatePrompt(appName: "Lumen Journal", versionString: "1.4", glossary: TranslationGlossary())
        #expect(prompt.slashCommand == "/mcp__applocalizer__translate_missing Lumen Journal")
    }

    @Test func theTextCarriesTheGlossaryAndTone() {
        let glossary = TranslationGlossary(terms: ["Lumen", "Face ID"], tone: .warmAndSimple)
        let prompt = AssistantTranslatePrompt(appName: "Lumen Journal", versionString: "1.4", glossary: glossary)
        #expect(prompt.text == "Use AppLocalizer to translate the missing store-page fields for Lumen Journal 1.4. "
            + "Keep “Lumen” and “Face ID” untranslated and keep the tone warm and simple. "
            + "Propose each field; I’ll review in AppLocalizer.")
    }

    @Test func withoutTermsOnlyTheToneIsAsked() {
        let prompt = AssistantTranslatePrompt(appName: "Tempo", versionString: "3.0", glossary: TranslationGlossary(terms: [], tone: .playful))
        #expect(prompt.text.contains("3.0. Keep the tone playful. Propose"))
        #expect(!prompt.text.contains("untranslated"))
    }
}
