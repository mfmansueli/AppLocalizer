//
//  ArtworkWebTextsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A Claude Design page's own words (`data-al="text"`): phrases written
/// once in the primary language, which AppLocalizer translates
/// (`ArtworkTextBook.phrases`) and writes into each language's render; a
/// language without its words yet is found, and they're checked like the
/// headline. Pages from before carry a version per language as children
/// with `lang`, which still work. Words outside every `data-al` are found.
@MainActor
@Suite("A page's own words in every language", .serialized)
struct ArtworkWebTextsTests {
    let renderer = ArtworkWebRenderer(width: 1)

    static let phrase = """
    <p class="quote" data-al="text" data-al-fit>Small   steps count.</p>
    """

    /// A page from before: a version per language.
    static let versioned = """
    <p class="quote" data-al="text" data-al-fit><span lang="en-US">Small steps count.</span>\
    <span lang="de-DE">Kleine Schritte zählen.</span><span lang="pt">Pequenos passos contam.</span></p>
    """

    static let css = """
    .quote { position: absolute; left: 200px; top: 900px; width: 1600px; height: 300px; margin: 0;
             font: 600 120px/1.1 system-ui; color: #ffffff; }
    """

    static var page: String { ArtworkWebFixtures.searchPage(extraCSS: css, extraBody: phrase) }
    static var versionedPage: String { ArtworkWebFixtures.searchPage(extraCSS: css, extraBody: versioned) }
    static let german = ["Small steps count.": "Kleine Schritte zählen."]

    // MARK: - Phrases written once

    @Test func thePrimaryLanguageShowsThePhraseAsWritten() async throws {
        let english = try await renderer.measure(ArtworkWebFixtures.request(Self.page))
        let element = try #require(english.elements(.text).first)
        #expect(element.text == "Small steps count.")
        #expect(element.source == "Small steps count.", "Its key: the words, spaces collapsed")
        #expect(element.isMissingLanguage == false)
        #expect(element.versions == nil)
        #expect(element.fits)
        #expect(english.phraseSources == ["Small steps count."])
    }

    @Test func eachLanguageShowsItsTranslation() async throws {
        let german = try await renderer.measure(ArtworkWebFixtures.request(Self.page, locale: "de-DE", phrases: Self.german))
        let element = try #require(german.elements(.text).first)
        #expect(element.text == "Kleine Schritte zählen.")
        #expect(element.source == "Small steps count.", "Still keyed by the primary language's words")
        #expect(element.isMissingLanguage == false)
    }

    @Test func aLanguageWithoutItsWordsShowsTheOriginal() async throws {
        let french = try await renderer.measure(ArtworkWebFixtures.request(Self.page, locale: "fr-FR"))
        let element = try #require(french.elements(.text).first)
        #expect(element.text == "Small steps count.")
        #expect(element.isMissingLanguage == true)

        var book = ArtworkTextBook()
        #expect(french.phrasesMissing(["en-US", "fr-FR", "de-DE"], primary: "en-US", book: book).map(\.locales) == [["fr-FR", "de-DE"]])
        book.setPhrases(["Small steps count.": ["de-DE": "Kleine Schritte zählen.", "fr-FR": "Les petits pas comptent."]], provenance: .written)
        #expect(french.phrasesMissing(["en-US", "fr-FR", "de-DE"], primary: "en-US", book: book).isEmpty)
    }

    @Test func thePagesPhrasesAreReadOnceInOrder() {
        func text(_ words: String) -> ArtworkWebMeasure.Element {
            ArtworkWebMeasure.Element(marker: "text", x: 0, y: 0, width: 10, height: 10, text: words, fits: true, isVisible: true, source: words)
        }
        let measure = ArtworkWebMeasure(elements: [text("Calm  mornings"), text("Small steps."), text("Calm mornings")], contentWidth: 0, contentHeight: 0)
        #expect(measure.phraseSources == ["Calm mornings", "Small steps."])
    }

    // MARK: - Pages from before

    @Test func aPageFromBeforeShowsEachLanguagesVersion() async throws {
        let english = try await renderer.measure(ArtworkWebFixtures.request(Self.versionedPage))
        let element = try #require(english.elements(.text).first)
        #expect(element.text == "Small steps count.")
        #expect(element.source == "Small steps count.")
        #expect(element.languages == ["en-US", "de-DE", "pt"])
        #expect(element.versions == ["en-US": "Small steps count.", "de-DE": "Kleine Schritte zählen.", "pt": "Pequenos passos contam."])

        let german = try await renderer.measure(ArtworkWebFixtures.request(Self.versionedPage, locale: "de-DE"))
        #expect(german.texts.map(\.text) == ["Kleine Schritte zählen."])
        #expect(german.elements(.text).first?.source == "Small steps count.", "Keyed by the primary language's version")
        let brazilian = try await renderer.measure(ArtworkWebFixtures.request(Self.versionedPage, locale: "pt-BR"))
        #expect(brazilian.texts.map(\.text) == ["Pequenos passos contam."], "pt is pt-BR's version")

        let french = try await renderer.measure(ArtworkWebFixtures.request(Self.versionedPage, locale: "fr-FR"))
        #expect(french.elements(.text).first?.isMissingLanguage == true)
        #expect(french.texts.isEmpty, "Without its version it shows nothing")
    }

    @Test func theBooksWordsWinOverAPagesOwnVersion() async throws {
        let edited = ["Small steps count.": "Jeder kleine Schritt zählt."]
        let german = try await renderer.measure(ArtworkWebFixtures.request(Self.versionedPage, locale: "de-DE", phrases: edited))
        #expect(german.texts.map(\.text) == ["Jeder kleine Schritt zählt."])
        let french = try await renderer.measure(
            ArtworkWebFixtures.request(Self.versionedPage, locale: "fr-FR", phrases: ["Small steps count.": "Les petits pas comptent."])
        )
        #expect(french.texts.map(\.text) == ["Les petits pas comptent."])
        #expect(french.elements(.text).first?.isMissingLanguage == false)
    }

    // MARK: - Words outside data-al

    @Test func wordsOutsideEveryDataAlAreFound() async throws {
        let html = ArtworkWebFixtures.searchPage(extraBody: """
        <p style="position: absolute; left: 200px; top: 1400px; font: 100px system-ui; color: #fff">Believe   in yourself</p>
        <p style="position: absolute; left: 200px; top: 1600px; font: 100px system-ui; color: #fff">9:41 ★★★</p>
        <p style="display: none">Hidden words</p>
        <svg width="400" height="200" style="position: absolute; left: 200px; top: 1700px">\
        <text x="0" y="100" font-size="80" fill="#fff">Calm</text></svg>
        """)
        let measure = try await renderer.measure(ArtworkWebFixtures.request(html))
        #expect(measure.strayText == ["Believe in yourself", "Calm"], "Digits and symbols, hidden text and the filled-in parts aren't")
        let clean = try await renderer.measure(ArtworkWebFixtures.request(Self.page))
        #expect(clean.strayText == [])
    }

    // MARK: - Checks

    @Test func aPhraseNotYetInTheLanguageIsAnError() async throws {
        let checks = try await checks(Self.page, locale: "fr-FR")
        let missing = try #require(checks.first { $0.kind == .page && $0.isError })
        #expect(missing.text.contains("1 of the page’s phrases aren’t in French yet"))
        #expect(missing.text.contains("Write them in Captions"))

        let translated = try await self.checks(Self.page, locale: "de-DE", phrases: Self.german)
        #expect(!translated.contains { $0.kind == .page && $0.isError })
    }

    @Test func aDirectionBeforeLocalizeIsntMissingAny() async throws {
        let checks = try await checks(Self.page, locale: "fr-FR", translateLater: true)
        #expect(!checks.contains { $0.kind == .page && $0.isError }, "Localize translates them later")
    }

    @Test func thePagesWordsAreCheckedLikeTheHeadline() async throws {
        let faint = Self.css.replacingOccurrences(of: "color: #ffffff", with: "color: #2a3a4a")
        let render = try await renderer.render(
            ArtworkWebFixtures.request(ArtworkWebFixtures.searchPage(extraCSS: faint, extraBody: Self.phrase)), behindText: true
        )
        let geometry = ArtworkCheckGeometry(web: render, kind: .search)
        #expect(geometry.texts.map(\.name) == ["the text ‘Small steps count.’"])
        #expect(geometry.textLayers.contains("Small steps count."))
        let checks = try await checks(ArtworkWebFixtures.searchPage(extraCSS: faint, extraBody: Self.phrase))
        #expect(checks.contains { $0.kind == .textContrast && $0.text.contains("the text ‘Small steps count.’") })

        let price = Self.phrase.replacingOccurrences(of: "Small   steps count.", with: "Only $4.99 today")
        let priced = try await self.checks(ArtworkWebFixtures.searchPage(extraCSS: Self.css, extraBody: price))
        #expect(priced.contains { $0.kind == .price && $0.isError }, "What Apple forbids, in the page's own words too")
    }

    @Test func versionsMatchByCodeThenLanguage() {
        #expect(ArtworkWebTextVersions.version(in: ["en-US", "de"], for: "en-US") == "en-US")
        #expect(ArtworkWebTextVersions.version(in: [" EN-us "], for: "en-US") == "EN-us")
        #expect(ArtworkWebTextVersions.version(in: ["de"], for: "de-DE") == "de")
        #expect(ArtworkWebTextVersions.version(in: ["pt-PT"], for: "pt-BR") == nil, "Another country's isn't its")
        #expect(ArtworkWebTextVersions.covers(["ja"], locale: "ja"))
        #expect(!ArtworkWebTextVersions.covers([], locale: "ja"))
    }

    // MARK: - What the assistant is told

    @Test func strayWordsAreRefusedInARunWithMoreThanOneLanguage() {
        let measure = ArtworkWebMeasure(elements: [], strayText: ["Believe in yourself"], contentWidth: 0, contentHeight: 0)
        let problems = MCPArtworkPreview.wordProblems(measure, kind: .search, locales: ["en-US", "de-DE"], primary: "en-US")
        #expect(problems.count == 1)
        #expect(problems.first?.contains("writes ‘Believe in yourself’ itself") == true)
        #expect(problems.first?.contains("written once in en-US (AppLocalizer translates them)") == true)
        let alone = MCPArtworkPreview.wordProblems(measure, kind: .search, locales: ["en-US"], primary: "en-US")
        #expect(alone.isEmpty, "One language: words of its own read right")
    }

    @Test func aDirectionsPhrasesArentProblems() {
        let phrase = ArtworkWebMeasure.Element(
            marker: "text", x: 0, y: 0, width: 10, height: 10, text: "Small steps count.", fits: true, isVisible: true,
            source: "Small steps count."
        )
        let measure = ArtworkWebMeasure(elements: [phrase], contentWidth: 0, contentHeight: 0)
        #expect(MCPArtworkPreview.wordProblems(measure, kind: .search, locales: ["en-US", "de-DE", "ja"], primary: "en-US").isEmpty)

        // A variant comes after Localize: its phrases must be in every language.
        var book = ArtworkTextBook()
        book.setPhrases(["Small steps count.": ["de-DE": "Kleine Schritte zählen."]], provenance: .written)
        let problems = MCPArtworkPreview.wordProblems(measure, kind: .search, locales: ["en-US", "de-DE", "ja"], primary: "en-US", book: book)
        #expect(problems == [
            "The search page’s phrase ‘Small steps count.’ has no words yet in ja: send them with phrases [{phrase, locale, text}].",
        ])
    }

    private func checks(
        _ html: String, locale: String = "en-US", phrases: [String: String] = [:], translateLater: Bool = false
    ) async throws -> [ArtworkCheck] {
        let render = try await renderer.render(ArtworkWebFixtures.request(html, locale: locale, phrases: phrases), behindText: true)
        let input = try ArtworkCheckInput(
            kind: .search, locale: #require(StoreLocaleCatalog.locale(code: locale)), image: render.image,
            geometry: ArtworkCheckGeometry(web: render, kind: .search), line: "Gentle daily quotes", page: render.measure,
            phrasesTranslateLater: translateLater
        )
        return await ArtworkChecker().checks(input)
    }
}
#endif
