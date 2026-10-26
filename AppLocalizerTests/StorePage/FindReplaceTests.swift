//
//  FindReplaceTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("FindReplace")
struct FindReplaceTests {
    private typealias Fixtures = StorePageFixtures

    // MARK: - Occurrences

    @Test func caseAndWholeWordOptions() {
        let text = "Lumen keeps notes. lumen is calm. Lumenous!"
        let count = { (caseSensitive: Bool, wholeWords: Bool) in
            FindReplace.occurrences(of: "Lumen", in: text, caseSensitive: caseSensitive, wholeWords: wholeWords).count
        }
        #expect(count(true, false) == 2)
        #expect(count(true, true) == 1)
        #expect(count(false, true) == 2)
        #expect(count(false, false) == 3)
    }

    @Test func wholeWordsRespectPunctuationAndAccents() {
        let text = "Plus, Plusieurs, «Plus» et Plus_1"
        let ranges = FindReplace.occurrences(of: "Plus", in: text, caseSensitive: true, wholeWords: true)
        #expect(ranges.map { String(text[$0]) } == ["Plus", "Plus"])
        #expect(FindReplace.occurrences(of: "", in: text, caseSensitive: true, wholeWords: false).isEmpty)
    }

    @Test func replacingRanges() {
        let text = "Lumen Plus and Lumen Plus"
        let ranges = FindReplace.occurrences(of: "Lumen Plus", in: text, caseSensitive: true, wholeWords: false)
        #expect(FindReplace.replacing(ranges, in: text, with: "Lumen Premium") == "Lumen Premium and Lumen Premium")
        #expect(FindReplace.replacing([], in: text, with: "x") == text)
    }

    // MARK: - Listing search

    @Test func sampleSearchFindsEveryDescription() {
        let query = FindReplaceQuery(find: "Lumen Plus", replacement: "Lumen Premium")
        let matches = StorePageSampleData.fetchedListing.matches(for: query)
        #expect(matches.map(\.key.locale.code) == ["en-US", "ar-SA", "en-GB", "fr-FR", "de-DE", "it", "ja", "pt-BR", "es-ES"])
        #expect(matches.allSatisfy { $0.key.field == .description })
        #expect(matches.allSatisfy { $0.replacedValue.contains("Lumen Premium") && !$0.replacedValue.contains("Lumen Plus") })
    }

    @Test func searchHonorsFieldsAndLocales() {
        let listing = Fixtures.listing()
        var query = FindReplaceQuery(find: "Lumen", replacement: "Lumina")
        #expect(listing.matches(for: query).map(\.key.id) == ["en-US.description", "de-DE.description"])
        query.fields = [.name]
        #expect(listing.matches(for: query).map(\.key.id) == ["en-US.name", "de-DE.name"])
        query.locales = [.german]
        #expect(listing.matches(for: query).map(\.key.id) == ["de-DE.name"])
    }

    @Test func readOnlyFieldsArentSearched() {
        let listing = Fixtures.listing(version: Fixtures.liveVersion)
        var query = FindReplaceQuery(find: "Lumen", replacement: "Lumina")
        #expect(listing.matches(for: query).isEmpty)
        query.fields = [.name, .description]
        #expect(listing.matches(for: query).map(\.key.field) == [.name, .name])
    }

    @Test func matchDetails() throws {
        let query = FindReplaceQuery(find: "Lumen", replacement: "Lumina")
        let match = try #require(Fixtures.listing().matches(for: query).first)
        #expect(match.occurrenceCount == 2)
        #expect(match.replacedValue == "Lumina keeps your notes private.\n\nUpgrade to Lumina Plus for themes and PDF export.")
        #expect(match.validation == .valid)
        #expect(!match.isOverLimit)
        #expect(match.snippet.prefix.isEmpty)
        #expect(match.snippet.match == "Lumen")
        #expect(match.snippet.suffix == " keeps your notes private. Up…")
        #expect(match.replacedSnippet.match == "Lumina")
    }

    @Test func snippetsTrimLongContextAndJoinLines() throws {
        let text = "Write daily.\n\nOr not, and Lumen keeps it."
        let snippet = try FindReplaceSnippet(text: text, range: #require(text.range(of: "Lumen")))
        #expect(snippet.prefix == "…ite daily. Or not, and ")
        #expect(snippet.suffix == " keeps it.")
        #expect(snippet.text == "…ite daily. Or not, and Lumen keeps it.")
    }

    @Test func overLimitReplacementsAreFlagged() throws {
        var listing = Fixtures.listing()
        listing.edit(.promotionalText, in: .german, to: String(repeating: "Lumen ", count: 28))
        let query = FindReplaceQuery(find: "Lumen", replacement: "Lumen Plus", locales: [.german])
        let match = try #require(listing.matches(for: query).first { $0.key.field == .promotionalText })
        #expect(match.isOverLimit)
        #expect(match.validation == .overLimit(count: 308, limit: ListingTextLimit(170)))
    }

    // MARK: - Replacing

    @Test func replacingAppliesYourEdits() {
        var listing = Fixtures.listing()
        let matches = listing.matches(for: FindReplaceQuery(find: "Lumen", replacement: "Lumina"))
        let replaced = listing.replace(matches)
        #expect(replaced == 2)
        #expect(listing.value(.description, in: .german) == "Lumina hält deine Notizen privat.")
        #expect(listing.pendingChanges.map(\.source) == [.you, .you])
    }

    @Test func staleMatchesAreSkipped() {
        var listing = Fixtures.listing()
        let matches = listing.matches(for: FindReplaceQuery(find: "Lumen", replacement: "Lumina"))
        listing.edit(.description, in: .german, to: "Lumen schützt deine Notizen.")
        let replaced = listing.replace(matches)
        #expect(replaced == 1)
        #expect(listing.value(.description, in: .german) == "Lumen schützt deine Notizen.")
    }
}
