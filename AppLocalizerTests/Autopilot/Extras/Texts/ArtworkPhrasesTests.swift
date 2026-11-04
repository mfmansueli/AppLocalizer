//
//  ArtworkPhrasesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The phrases Claude Design writes on the header and search pages
/// (`data-al="text"`) are written once in the primary language and
/// translated in AppLocalizer like the captions: the book keeps each
/// language's words, the direction knows each page's phrases, Localize
/// asks the assistant for the ones a language lacks or that don't fit,
/// and a page from before that carries its own versions has them read in.
@MainActor
@Suite("Artwork · the pages' phrases, translated in AppLocalizer", .serialized)
struct ArtworkPhrasesTests {
    private static let phrase = StudioDebugWebArtwork.phrase

    private static func caption(_ words: String, _ provenance: CaptionProvenance = .written) -> ScreenshotCaption {
        ScreenshotCaption(headline: words, subhead: nil, provenance: provenance)
    }

    // MARK: - The book

    @Test func theBookKeepsEachPhrasePerLanguage() {
        var book = ArtworkTextBook()
        #expect(book.isEmpty)
        book.setPhrase(Self.caption("Kleine Schritte zählen."), source: "Small  steps\ncount.", locale: "de-DE")
        #expect(!book.isEmpty)
        #expect(book.phrase(Self.phrase, locale: "de-DE")?.headline == "Kleine Schritte zählen.", "Keyed by its words, spaces collapsed")
        #expect(book.phrase(Self.phrase, locale: "fr-FR") == nil)
        #expect(book.phraseTexts(locale: "de-DE") == [Self.phrase: "Kleine Schritte zählen."])
        #expect(book.phraseTexts(locale: "fr-FR").isEmpty)

        book.setPhrase(nil, source: Self.phrase, locale: "de-DE")
        #expect(book.isEmpty, "Removing the last one leaves nothing")
        #expect(book.phrases == nil)
    }

    @Test func versionsAreLaidOverTheBook() {
        var book = ArtworkTextBook()
        book.setPhrases([Self.phrase: ["de-DE": " Kleine  Schritte zählen. ", "fr-FR": "  "]], provenance: .machineTranslated)
        #expect(book.phrase(Self.phrase, locale: "de-DE") == Self.caption("Kleine Schritte zählen.", .machineTranslated))
        #expect(book.phrase(Self.phrase, locale: "fr-FR") == nil, "Blank words are left out")
    }

    @Test func aBookFromBeforeHasNoPhrases() throws {
        var book = ArtworkTextBook()
        book.set(Self.caption("Calm journal"), role: .search, locale: "en-US")
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(book)) as? [String: Any])
        json["phrases"] = nil
        let decoded = try JSONDecoder().decode(ArtworkTextBook.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.phrases == nil)
        #expect(decoded.headline(.search, locale: "en-US") == "Calm journal")

        book.setPhrase(Self.caption("Kleine Schritte zählen."), source: Self.phrase, locale: "de-DE")
        #expect(try JSONDecoder().decode(ArtworkTextBook.self, from: JSONEncoder().encode(book)) == book)
    }

    // MARK: - The direction

    @Test func theDesignKnowsEachPagesPhrases() throws {
        var design = StudioDebugWebArtwork.quietIndigo
        #expect(design.phrases == nil)
        #expect(!design.hasReadPhrases, "A direction from before: Localize reads them")
        design.setPhrases(["Calm mornings"], for: .header)
        #expect(!design.hasReadPhrases, "The search page isn't read yet")
        design.setPhrases([Self.phrase, "Calm mornings"], for: .search)
        #expect(design.hasReadPhrases)
        #expect(design.allPhrases() == ["Calm mornings", Self.phrase], "Each once, header first")
        #expect(design.allPhrases(in: [.search]) == [Self.phrase, "Calm mornings"])
        #expect(design.kind(writing: Self.phrase) == .search)
        #expect(design.kind(writing: "Calm mornings") == .header, "The first canvas that writes it")
        #expect(design.kind(writing: "Big leaps") == nil)

        let revised = AutopilotArtworkDesign(pages: [.search: "<p>New</p>"]).laid(over: design)
        #expect(revised.phrases(for: .search) == nil, "A new page's phrases are read again")
        #expect(revised.phrases(for: .header) == ["Calm mornings"], "The page it keeps keeps its phrases")

        #expect(try JSONDecoder().decode(AutopilotArtworkDesign.self, from: JSONEncoder().encode(design)) == design)
        let before = try JSONDecoder().decode(AutopilotArtworkDesign.self, from: Data(#"{"pages":{"search":"<p>x</p>"}}"#.utf8))
        #expect(before.phrases == nil)
    }

    // MARK: - Localize asks for them

    /// English and German have their words (German's too long for the
    /// box), French has none: the assistant translates French's and
    /// shortens German's. The page writing it twice asks once.
    @Test func localizeAsksForEachPhraseALanguageLacksOrThatDoesntFit() async {
        var book = ArtworkTextBook()
        for (locale, headline) in ["en-US": "Calm journal", "de-DE": "Ruhiges Tagebuch", "fr-FR": "Journal calme"] {
            book.set(Self.caption(headline), role: .search, locale: locale)
        }
        let long = "Jeder noch so kleine Schritt zählt auf dem langen Weg"
        book.setPhrase(Self.caption(long), source: Self.phrase, locale: "de-DE")
        let checker = AutopilotArtworkTextChecker(
            template: ScreenshotsSampleData.template, texts: book, size: .headerAndSearch, catalog: ScreenshotsTestFixtures.fonts,
            primaryLocale: "en-US"
        )
        var sent: [String: [String: String]] = [:]
        let needs = await checker.needs(locales: ["en-US", "de-DE", "fr-FR"], design: StudioDebugWebArtwork.withPhrase) { _, kind, locale, headline, phrases in
            sent["\(kind.rawValue).\(locale.code)"] = phrases
            let words = phrases[Self.phrase]
            let shown = ArtworkWebMeasure.Element(
                marker: "text", x: 0, y: 0, width: 10, height: 10, text: words ?? Self.phrase, fits: words != long, isVisible: true,
                source: Self.phrase, isMissingLanguage: words == nil && locale.code != "en-US"
            )
            let title = ArtworkWebMeasure.Element(marker: "headline", x: 0, y: 0, width: 10, height: 10, text: headline, fits: true, isVisible: true)
            return ArtworkWebMeasure(elements: [title, shown], contentWidth: 0, contentHeight: 0)
        }
        #expect(needs == [
            AutopilotArtworkTextNeed(locale: "de-DE", role: .search, problem: .tooLong, headline: long, phrase: Self.phrase),
            AutopilotArtworkTextNeed(locale: "fr-FR", role: .search, problem: .missing, phrase: Self.phrase),
        ])
        #expect(sent["search.de-DE"] == [Self.phrase: long], "Each language's page is measured with its words")
        #expect(sent["header.fr-FR"] == [:])
        #expect(AutopilotArtworkTextWork(needs).summary == "1 phrase to translate, 1 phrase to shorten")
    }

    @Test func theAssistantTranslatesEachPhraseAsGiven() throws {
        let json = AutopilotNextStep.writeArtworkTextsJSON([
            AutopilotArtworkTextNeed(locale: "fr-FR", role: .search, problem: .missing, phrase: Self.phrase),
            AutopilotArtworkTextNeed(locale: "de-DE", role: .header, problem: .tooLong, headline: "Jeder kleine Schritt zählt", phrase: "Calm mornings"),
        ])
        let texts = try #require(json["texts"]?.arrayValue)
        #expect(texts[0] == ["locale": "fr-FR", "placement": "text", "phrase": "Small steps count.", "problem": "missing", "on": "search"])
        #expect(texts[1] == [
            "locale": "de-DE", "placement": "text", "phrase": "Calm mornings", "problem": "too_long", "on": "header",
            "headline": "Jeder kleine Schritt zählt",
        ])
        let how = try #require(json["how"]?.stringValue)
        #expect(how.contains("not word by word"))
        #expect(how.contains("(and phrase, exactly as given, for text)"))
    }

    // MARK: - Pages from before

    @Test func aPagesOwnVersionsFillOnlyWhatTheBookLacks() {
        let element = ArtworkWebMeasure.Element(
            marker: "text", x: 0, y: 0, width: 10, height: 10, text: Self.phrase, fits: true, isVisible: true, source: Self.phrase,
            versions: ["en-US": Self.phrase, "de": "Kleine Schritte zählen.", "fr-FR": " Les petits  pas comptent. "]
        )
        var book = ArtworkTextBook()
        book.setPhrase(Self.caption("Jeder Schritt zählt.", .edited), source: Self.phrase, locale: "de-DE")
        AutopilotCenter.importVersions(
            of: element, locales: ["en-US", "de-DE", "fr-FR", "ja"], primary: "en-US", provenance: .assistant(client: "Claude Design", date: .distantPast),
            into: &book
        )
        #expect(book.phrase(Self.phrase, locale: "de-DE")?.headline == "Jeder Schritt zählt.", "What the person wrote stays")
        #expect(book.phrase(Self.phrase, locale: "fr-FR") == Self.caption("Les petits pas comptent.", .assistant(client: "Claude Design", date: .distantPast)))
        #expect(book.phrase(Self.phrase, locale: "ja") == nil, "No version of its own")
        #expect(book.phrase(Self.phrase, locale: "en-US") == nil, "The primary language is the page's own words")
    }

    /// A direction from before writes a version per language and has no
    /// phrases read: Localize reads them off its pages and keeps its
    /// versions in the book, so Captions shows them.
    @Test func localizeReadsThePagesPhrases() async throws {
        let versioned = """
        <p data-al="text" style="position: absolute; left: 300px; top: 1950px; width: 1700px; margin: 0; font: 600 100px/1.1 system-ui; \
        color: #fff"><span lang="en-US">Small steps count.</span><span lang="de-DE">Kleine Schritte zählen.</span></p>
        """
        var design = StudioDebugWebArtwork.quietIndigo
        design.setPage(design.page(for: .search)?.replacingOccurrences(of: "</body>", with: versioned + "</body>"), for: .search)
        var run = StudioDebugExtras.run(.localize)
        run.plan.localeCodes = ["en-US", "de-DE", "fr-FR"]
        #expect(run.plan.artworkKinds == [.header, .search])
        for index in run.directions.indices { run.directions[index].artworkDesign = design }
        let direction = try #require(run.chosenDirection)
        let center = AutopilotTestFixtures.center()
        center.install(run)
        let services = AutopilotTestFixtures.services(center)
        let context = AutopilotTestFixtures.context(services)
        let document = try await services.loadDocument(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)

        let (read, saved) = await center.readPhrases(of: run, in: document, context: context)
        #expect(read.chosenDirection?.artworkDesign?.phrases(for: .search) == [Self.phrase])
        #expect(read.chosenDirection?.artworkDesign?.phrases(for: .header) == [])
        #expect(center.run(for: run.appID)?.chosenDirection?.artworkDesign?.phrases(for: .search) == [Self.phrase], "On the run too")
        let german = saved.artworkTexts?.phrase(Self.phrase, locale: "de-DE")
        #expect(german == Self.caption(
            "Kleine Schritte zählen.", .assistant(client: direction.client ?? direction.sourceTitle, date: direction.receivedAt)
        ))
        #expect(saved.artworkTexts?.phrase(Self.phrase, locale: "fr-FR") == nil, "Left for the assistant to translate")
        let stored = try await services.loadDocument(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(stored.artworkTexts?.phrase(Self.phrase, locale: "de-DE") != nil, "Saved")
    }

    // MARK: - Loops

    @Test func eachLanguageAndItsWordsHaveTheirOwnLoop() {
        let html = StudioDebugWebArtwork.withPhrase.page(for: .search) ?? ""
        let brazil = ArtworkWebLoop.posterKey(poster: "p", html: html, locale: "pt-BR")
        #expect(brazil != ArtworkWebLoop.posterKey(poster: "p", html: html, locale: "pt-PT"), "Posters that match still move with other words")
        #expect(brazil == ArtworkWebLoop.posterKey(poster: "p", html: html, locale: "pt-BR"))
        let german = ArtworkWebLoop.posterKey(poster: "p", html: html, locale: "de-DE", phrases: [Self.phrase: "Kleine Schritte zählen."])
        #expect(german != ArtworkWebLoop.posterKey(poster: "p", html: html, locale: "de-DE", phrases: [Self.phrase: "Jeder Schritt zählt."]))
    }
}
#endif
