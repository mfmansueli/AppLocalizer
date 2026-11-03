//
//  ArtworkTextsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The header's and search image's own texts: what each role allows, the
/// book they're kept in, how they're counted, and what Localize asks the
/// assistant to write.
@Suite("Artwork texts")
struct ArtworkTextsTests {
    @Test func eachRoleHasItsJob() {
        #expect(ArtworkTextRole.search.maximumWords == 5)
        #expect(ArtworkTextRole.header.maximumWords == 3)
        #expect(!ArtworkTextRole.search.isOptional)
        #expect(ArtworkTextRole.header.isOptional)
        #expect(ArtworkTextRole.roles(for: .headerAndSearch) == [.search, .header])
        #expect(ArtworkTextRole.roles(for: .wide) == [.search], "One 16:9 image carries the search headline")
        #expect(ArtworkTextRole.search.kind(for: .wide) == .wide)
        #expect(ArtworkTextRole.header.kind(for: .headerAndSearch) == .header)
        #expect(ArtworkTextRole.role(for: .wide) == .search)
        #expect(ArtworkTextRole.placementRoles(for: .wide) == [.header, .search], "But it does both jobs")
        #expect(ArtworkTextRole.placementTitle(of: [.header]) == "header")
        #expect(ArtworkTextRole.placementTitle(of: [.header, .search]) == "header and search image")
    }

    @Test func theBookKeepsEachRolesTextPerLanguage() {
        var book = ArtworkTextBook()
        book.set(ScreenshotCaption(headline: "Journal in seconds"), role: .search, locale: "en-US")
        book.set(ScreenshotCaption(headline: "Calm"), role: .header, locale: "en-US")
        #expect(book.headline(.search, locale: "en-US") == "Journal in seconds")
        #expect(book.headline(.header, locale: "en-US") == "Calm")
        #expect(book.headline(.search, locale: "de-DE") == "")
        book.set(ScreenshotCaption(headline: ""), role: .header, locale: "en-US")
        #expect(book.text(.header, locale: "en-US") == nil, "An empty header line is none")
        #expect(!book.isEmpty)
    }

    @Test(arguments: [
        ("Journal in seconds", ArtworkTextRole.search, "en-US", false),
        ("Write your private journal every single day", .search, "en-US", true),
        ("Ein Tagebuch, das sich überall mühelos schreibt", .search, "de-DE", true),
        ("Calm mornings", .header, "en-US", false),
        ("Your calm morning page", .header, "en-US", true),
        ("毎日の日記", .search, "ja", false),
    ])
    func tooLongIsCounted(text: String, role: ArtworkTextRole, locale: String, tooLong: Bool) {
        #expect(ArtworkTextCount(text, role: role, locale: locale).isTooLong == tooLong)
    }

    @MainActor @Test func localizeAsksForAMissingSearchHeadlineAndOneThatWontFit() {
        var book = ArtworkTextBook()
        book.set(ScreenshotCaption(headline: "Journal in seconds"), role: .search, locale: "en-US")
        book.set(
            ScreenshotCaption(headline: "Donaudampfschifffahrtsgesellschaftskapitänsmützenabzeichensammlungsbeauftragter"),
            role: .search, locale: "de-DE"
        )
        let checker = AutopilotArtworkTextChecker(
            template: ScreenshotsSampleData.template, texts: book, size: .headerAndSearch, catalog: ScreenshotsTestFixtures.fonts
        )
        let needs = checker.needs(locales: ["en-US", "de-DE", "fr-FR"])
        #expect(needs.map(\.locale) == ["de-DE", "fr-FR"], "English fits; no header line is needed anywhere")
        #expect(needs.first?.problem == .tooLong)
        #expect(needs.first?.role == .search)
        #expect(needs.last == AutopilotArtworkTextNeed(locale: "fr-FR", role: .search, problem: .missing))
    }

    @Test func theAssistantIsToldWhatEachTextIsFor() throws {
        let json = AutopilotNextStep.writeArtworkTextsJSON([
            AutopilotArtworkTextNeed(locale: "fr-FR", role: .search, problem: .missing),
            AutopilotArtworkTextNeed(locale: "de-DE", role: .header, problem: .tooLong, headline: "Dein ruhiger Morgen beginnt hier"),
        ])
        #expect(json["action"] == "write_artwork_texts")
        let texts = try #require(json["texts"]?.arrayValue)
        #expect(texts[0] == ["locale": "fr-FR", "placement": "search", "problem": "missing", "maxWords": 5, "maxCharacters": 32])
        #expect(texts[1] == [
            "locale": "de-DE", "placement": "header", "problem": "too_long", "maxWords": 3, "headline": "Dein ruhiger Morgen beginnt hier",
        ])
        let how = try #require(json["how"]?.stringValue)
        #expect(how.contains("keywords and subtitle"))
        #expect(how.contains("propose_captions"))
    }
}
#endif
