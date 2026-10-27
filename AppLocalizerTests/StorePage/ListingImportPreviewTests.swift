//
//  ListingImportPreviewTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ListingImportPreview")
struct ListingImportPreviewTests {
    private typealias Fixtures = StorePageFixtures

    private func samplePreview() throws -> ListingImportPreview {
        let fileName = StorePageSampleData.translatorFileName
        let document = try ListingTransfer.read(Data(StorePageSampleData.translatorXLIFF.utf8), fileName: fileName)
        return StorePageSampleData.fetchedListing.importPreview(for: document, fileName: fileName)
    }

    private func document(_ entries: ListingTransferEntry...) -> ListingTransferDocument {
        ListingTransferDocument(format: .csv, entries: entries)
    }

    private func entry(_ localeCode: String, _ fieldName: String, _ value: String) -> ListingTransferEntry {
        ListingTransferEntry(localeCode: localeCode, fieldName: fieldName, value: value)
    }

    // MARK: - The translator's file

    @Test func sampleFileHasFiveChangesAndTwoProblems() throws {
        let preview = try samplePreview()
        #expect(preview.changes.map(\.key.id) == [
            "fr-FR.promotionalText", "de-DE.whatsNew", "es-MX.description", "ja.keywords", "it.promotionalText",
        ])
        #expect(preview.localeCount == 5)
        #expect(preview.summary == "Lumen-1.4-translations.xliff · 5 changes in 5 locales · 2 problems")
        #expect(preview.applyTitle == "Apply 5 Changes")
    }

    @Test func sampleFileProblems() throws {
        let problems = try samplePreview().problems
        #expect(problems.count == 2)
        #expect(problems.first == .unknownLocale(code: "pt", suggestions: [.portugueseBrazil, .portuguesePortugal], skippedCount: 9))
        #expect(
            problems.first?.message
                == "“pt” isn’t an App Store locale. Did you mean Portuguese (Brazil) or Portuguese (Portugal)? 9 fields skipped."
        )
        #expect(problems.first?.isError == false)
        #expect(problems.last?.message == "French subtitle is 33 characters; the limit is 30. Skipped.")
        #expect(problems.last?.isError == true)
    }

    @Test func changesKeepTheOldValue() throws {
        let change = try #require(samplePreview().changes.first { $0.key.locale == .spanishMexico })
        #expect(change.oldValue.isEmpty)
        #expect(!change.newValue.isEmpty)
        #expect(change.isSelected)
    }

    @Test func applyingOnlyTheSelectedChanges() throws {
        var preview = try samplePreview()
        preview.toggle(ListingFieldKey(.japanese, .keywords))
        #expect(preview.applyTitle == "Apply 4 Changes")
        var listing = StorePageSampleData.fetchedListing
        let applied = listing.apply(preview)
        #expect(applied == 4)
        #expect(listing.pendingChanges.count == 4)
        #expect(listing.pendingChanges.allSatisfy { $0.source == .you && !$0.isBlocked })
        #expect(listing.change(for: ListingFieldKey(.japanese, .keywords)) == nil)
        #expect(listing.value(.subtitle, in: .french) == "Notes privées, idées douces")
    }

    @Test func selectingAllOrNone() throws {
        var preview = try samplePreview()
        preview.selectAll(false)
        #expect(preview.selectedChanges.isEmpty)
        #expect(preview.applyTitle == "Apply 0 Changes")
        preview.setSelected(ListingFieldKey(.italian, .promotionalText), true)
        #expect(preview.applyTitle == "Apply 1 Change")
        preview.selectAll(true)
        #expect(preview.selectedChanges.count == 5)
    }

    // MARK: - Rules

    @Test func emptyValuesAndRepeatsAreIgnored() {
        let preview = Fixtures.listing().importPreview(for: document(
            entry("de-DE", "promotionalText", "Neu"),
            entry("de-DE", "promotionalText", "Später"),
            entry("de-DE", "keywords", "  "),
            entry("de", "whatsNew", "Fehlerbehebungen.")
        ))
        #expect(preview.changes.map(\.newValue) == ["Neu", "Fehlerbehebungen."])
        #expect(preview.changes.map(\.key.id) == ["de-DE.promotionalText", "de-DE.whatsNew"])
        #expect(preview.problems.isEmpty)
        #expect(preview.summary == "2 changes in 1 locale")
    }

    @Test func unknownLocalesAndFieldsAreCounted() {
        let preview = Fixtures.listing().importPreview(for: document(
            entry("xx", "name", "Lumen"),
            entry("xx", "subtitle", "Notes"),
            entry("", "name", "Lumen"),
            entry("de-DE", "title", "Lumen")
        ))
        #expect(preview.changes.isEmpty)
        #expect(preview.problems.map(\.message) == [
            "“xx” isn’t an App Store locale. 2 fields skipped.",
            "Part of the file has no target language. 1 field skipped.",
            "“title” isn’t a store page field. 1 value skipped.",
        ])
        #expect(preview.problems.allSatisfy { !$0.isError })
        #expect(preview.summary == "0 changes in 0 locales · 3 problems")
    }

    @Test func invalidValuesAreSkippedAsErrors() {
        let preview = Fixtures.listing().importPreview(for: document(
            entry("de-DE", "keywords", String(repeating: "ü", count: 51)),
            entry("de-DE", "privacyPolicyUrl", "lumen.example/de/privacy")
        ))
        #expect(preview.changes.isEmpty)
        #expect(preview.problems.map(\.message) == [
            "German keywords are 102 bytes; the limit is 100. Skipped.",
            "German privacy policy URL isn’t a full https:// address. Skipped.",
        ])
        let allErrors = preview.problems.allSatisfy(\.isError)
        #expect(allErrors)
    }

    @Test func readOnlyVersionsSkipVersionFields() {
        var listing = Fixtures.listing(version: Fixtures.liveVersion)
        let preview = listing.importPreview(for: document(
            entry("de-DE", "description", "Neu"),
            entry("de-DE", "whatsNew", "Neu"),
            entry("de-DE", "name", "Lumen")
        ))
        #expect(preview.changes.map(\.key.id) == ["de-DE.name"])
        #expect(preview.problems.map(\.message) == ["Version 1.9 is read-only. 2 fields skipped."])
        let applied = listing.apply(preview)
        #expect(applied == 1)
    }
}
