//
//  GlossaryProtectorTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("GlossaryProtector")
struct GlossaryProtectorTests {
    private let protector = StorePageSampleData.glossary.protector

    @Test func longerTermsComeFirst() {
        #expect(protector.terms == ["Lumen Plus", "Face ID", "iCloud", "Lumen"])
        #expect(GlossaryProtector(terms: ["Lumen", " Lumen ", "", "  "]).terms == ["Lumen"])
    }

    @Test func protectingReplacesTermsWithPlaceholders() {
        let protected = protector.protect("Lumen Plus unlocks Lumen themes.")
        #expect(protected.text == "⟦0⟧ unlocks ⟦1⟧ themes.")
        #expect(protected.terms == ["Lumen Plus", "Lumen"])
        #expect(protected.original == "Lumen Plus unlocks Lumen themes.")
    }

    @Test func placeholdersAreNumberedInOrderOfUse() {
        let protected = protector.protect("Unlock with Face ID and sync with iCloud. Face ID stays on device.")
        #expect(protected.text == "Unlock with ⟦0⟧ and sync with ⟦1⟧. ⟦0⟧ stays on device.")
        #expect(protected.terms == ["Face ID", "iCloud"])
    }

    @Test func onlyWholeWordsWithTheSameCase() {
        let protected = protector.protect("Lumenous lumen, Lumen's")
        #expect(protected.text == "Lumenous lumen, ⟦0⟧'s")
        #expect(protector.protect("Nothing to keep.").terms.isEmpty)
    }

    @Test func restoringPutsTermsBack() {
        let protected = protector.protect("Lumen Plus unlocks Lumen themes.")
        #expect(protected.restore("⟦0⟧ schaltet ⟦1⟧-Designs frei.") == "Lumen Plus schaltet Lumen-Designs frei.")
        #expect(protected.restore("⟦ 1 ⟧ und ⟦0⟧") == "Lumen und Lumen Plus")
        #expect(protected.restore("⟦7⟧ bleibt") == "⟦7⟧ bleibt")
    }

    @Test func missingPlaceholdersAreReported() {
        let protected = protector.protect("Lumen Plus unlocks Lumen themes.")
        #expect(protected.missingTerms(in: "⟦0⟧ schaltet Designs frei.") == ["Lumen"])
        #expect(protected.missingTerms(in: "⟦1⟧ ⟦0⟧").isEmpty)
    }

    // MARK: - Glossary

    @Test func glossaryTermsAreTrimmedAndUnique() {
        var glossary = TranslationGlossary(terms: ["Lumen", " lumen ", "Face ID"])
        #expect(glossary.terms == ["Lumen", "Face ID"])
        glossary.add("Weekly Reflections")
        glossary.add("   ")
        glossary.remove("Face ID")
        #expect(glossary.terms == ["Lumen", "Weekly Reflections"])
        #expect(glossary.tone == .warmAndSimple)
        #expect(StorePageSampleData.settingsGlossary.terms.count == 5)
    }

    @Test func tones() {
        #expect(TranslationTone.allCases.map(\.title) == ["Warm and simple", "Neutral", "Playful", "Professional"])
        #expect(TranslationTone.warmAndSimple.promptPhrase == "warm and simple")
    }
}
