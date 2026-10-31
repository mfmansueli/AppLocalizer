//
//  StudioStoreTextsTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The version's languages, names and subtitles for the preview's header.
@Suite("StudioStoreTexts")
struct StudioStoreTextsTests {
    @Test func thePrimaryLanguageComesFirst() {
        var content = StorePageContentFixtures.editable
        content.locales = [.german, .englishUS]
        let texts = StudioStoreTexts(content: content)
        #expect(texts.locales.map(\.code) == ["en-US", "de-DE"])
    }

    @Test func namesAndSubtitlesAreKeptPerLanguage() {
        let texts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        #expect(texts.names == ["en-US": "Lumen: Journal", "de-DE": "Lumen: Tagebuch"])
        #expect(texts.subtitles == ["en-US": "Private notes, gentle prompts", "de-DE": "Private Notizen, sanfte Fragen"])
    }

    @Test func aPrimaryLanguageWithoutANameUsesTheAppsName() {
        var content = StorePageContentFixtures.editable
        content.texts[.englishUS]?[.name] = nil
        let texts = StudioStoreTexts(content: content)
        #expect(texts.names["en-US"] == "Lumen Journal")
        #expect(texts.names["de-DE"] == "Lumen: Tagebuch")
    }

    @Test func aLanguageWithoutTextsUsesThePrimarys() {
        let texts = StudioStoreTexts(content: StorePageContentFixtures.editable)
        #expect(texts.name(for: "de-DE", primary: "en-US") == "Lumen: Tagebuch")
        #expect(texts.name(for: "fr-FR", primary: "en-US") == "Lumen: Journal")
        #expect(texts.subtitle(for: "fr-FR", primary: "en-US") == "Private notes, gentle prompts")
        #expect(texts.name(for: "fr-FR", primary: "it") == nil)
        #expect(texts.subtitle(for: "fr-FR", primary: "it") == nil)
        #expect(StudioStoreTexts().name(for: "en-US", primary: "en-US") == nil)
    }
}
