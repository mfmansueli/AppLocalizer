//
//  CaptionsArtworkPhrasesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Captions has a column per phrase the header and search pages write
/// themselves, after Search results and Header: the primary language
/// shows the page's own words, each other language its translation (or
/// Missing), and the editor writes them like the placements' texts.
@MainActor
@Suite("Captions · the pages' phrases")
struct CaptionsArtworkPhrasesTests {
    private static let phrase = StudioDebugWebArtwork.phrase

    private static func caption(_ words: String, _ provenance: CaptionProvenance = .written) -> ScreenshotCaption {
        ScreenshotCaption(headline: words, subhead: nil, provenance: provenance)
    }

    /// Quiet Indigo's artwork made with its phrase, translated into German.
    private static var document: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        var texts = ArtworkTextBook()
        texts.set(caption("Your calm daily journal"), role: .search, locale: "en-US")
        texts.setPhrase(caption("Kleine Schritte zählen.", .assistant(client: "Claude Code", date: .distantPast)), source: phrase, locale: "de-DE")
        document.artworkTexts = texts
        document.extras = ScreenshotExtras(
            directionName: "Quiet Indigo", madeAt: .distantPast, artworkSize: .headerAndSearch, artworkDesign: StudioDebugWebArtwork.withPhrase
        )
        return document
    }

    @Test func eachPhraseIsAColumnAfterTheHeader() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(Self.document)
        let captions = model.captions
        #expect(captions.artworkRoles == [.search, .header])
        #expect(captions.artworkPhrases == [Self.phrase])
        let rows = captions.allRows

        let english = try #require(rows.first { $0.locale.code == "en-US" }?.artworkCells)
        #expect(english.map(\.columnTitle) == ["Search results", "Header", "Phrase 1"])
        let own = try #require(english.last)
        #expect(own.key == ArtworkTextKey(locale: "en-US", role: .search, phrase: Self.phrase), "On the search page")
        #expect(own.text?.headline == Self.phrase, "The page's own words")
        #expect(!own.isMissing)
        #expect(own.count == nil, "A phrase's limit is its box, not a word count")
        #expect(own.identifierSuffix == "text.0")

        let german = try #require(rows.first { $0.locale.code == "de-DE" }?.artworkCells.last)
        #expect(german.text?.headline == "Kleine Schritte zählen.")
        #expect(german.assistant == "Claude Code")

        let french = try #require(rows.first { $0.locale.code == "fr-FR" }?.artworkCells.last)
        #expect(french.isMissing)
        #expect(french.emptyTitle == "Missing")
        #expect(french.needsAttention)
        #expect(french.accessibilityText(localeName: "French") == "French phrase 1: Missing")
    }

    @Test func withoutPhrasesThereAreNoColumns() async {
        var document = Self.document
        document.extras?.artworkDesign = StudioDebugWebArtwork.quietIndigo
        let (model, _) = await ScreenshotsTestFixtures.viewModel(document)
        #expect(model.captions.artworkPhrases.isEmpty)
        #expect(model.captions.allRows.first?.artworkCells.count == 2)
    }

    @Test func aPhraseIsWrittenInTheEditor() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(Self.document)
        let editor = model.captions.artworkEditor
        editor.select(ArtworkTextKey(locale: "fr-FR", role: .search, phrase: Self.phrase))
        #expect(editor.title == "Phrase 1 · French")
        #expect(editor.isPhrase)
        #expect(editor.headline.isEmpty)
        #expect(editor.prompt == "The phrase in French")
        #expect(editor.guidance.contains("not word by word"))
        #expect(editor.sources.map(\.title) == ["Original · English (U.S.)"])
        #expect(editor.sources.map(\.text) == [Self.phrase])
        #expect(editor.countDetail == nil)

        editor.setHeadline(" Les petits  pas comptent. ")
        await editor.commitEdits()
        #expect(model.document?.artworkTexts?.phrase(Self.phrase, locale: "fr-FR") == Self.caption("Les petits pas comptent.", .edited))
        #expect(model.studio.artworkPhrases(in: "fr-FR") == [Self.phrase: "Les petits pas comptent."], "The page shows it")
    }

    /// In the primary language the editor starts from the page's words; a
    /// change shows on the page, and the same words again remove it.
    @Test func thePrimaryLanguagesWordsCanChange() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel(Self.document)
        let editor = model.captions.artworkEditor
        editor.select(ArtworkTextKey(locale: "en-US", role: .search, phrase: Self.phrase))
        #expect(editor.headline == Self.phrase)
        #expect(editor.sources.isEmpty)
        #expect(editor.guidance.contains("every language translates from the original words"))

        editor.setHeadline("Small steps.")
        await editor.commitEdits()
        #expect(model.document?.artworkTexts?.phrase(Self.phrase, locale: "en-US")?.headline == "Small steps.")
        #expect(model.studio.artworkPhrases(in: "en-US") == [Self.phrase: "Small steps."])

        editor.setHeadline(Self.phrase)
        await editor.commitEdits()
        #expect(model.document?.artworkTexts?.phrase(Self.phrase, locale: "en-US") == nil)
        #expect(model.document?.artworkTexts?.phrase(Self.phrase, locale: "de-DE") != nil, "The translations stay")
    }
}
#endif
