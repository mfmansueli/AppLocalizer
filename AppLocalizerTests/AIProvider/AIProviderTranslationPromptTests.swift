//
//  AIProviderTranslationPromptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What the AI provider is told for each field.
@Suite("AIProviderTranslationPrompt")
struct AIProviderTranslationPromptTests {
    private func prompt(_ field: ListingField, _ text: String = "Text") -> AIProviderTranslationPrompt {
        AIProviderTranslationPrompt(text: text, field: field, source: .englishUS, target: .german, tone: .warmAndSimple)
    }

    @Test func keywordsAreChosenForSearchWithinTheirBytes() {
        let system = prompt(.keywords).system
        #expect(system.contains("Choose the words people searching in this language would type"))
        #expect(system.contains("It must fit in 100 bytes in UTF-8."))
    }

    @Test func longFieldsKeepTheirLayout() {
        #expect(prompt(.description).system.contains("Keep its paragraphs, line breaks and lists."))
        #expect(prompt(.whatsNew).system.contains("This is What's New for a release."))
        #expect(prompt(.whatsNew).system.contains("It must fit in 4000 characters."))
    }

    @Test func glossaryPlaceholdersAreKept() {
        #expect(prompt(.subtitle).system.contains("Placeholders such as ⟦0⟧ stand for brand names"))
    }

    @Test func theUserMessageNamesTheFieldTheLanguagesAndTheText() {
        let user = prompt(.promotionalText, "Write a little every day.").user
        #expect(user == "Translate this promotional text from English (U.S.) into German:\n\nWrite a little every day.")
    }
}
