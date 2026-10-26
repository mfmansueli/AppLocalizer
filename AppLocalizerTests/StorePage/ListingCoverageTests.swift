//
//  ListingCoverageTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("Listing coverage")
struct ListingCoverageTests {
    private typealias Fixtures = StorePageFixtures

    private func cell(_ grid: ListingCoverageGrid, _ locale: StoreLocale, _ field: ListingField) -> ListingCoverageCell? {
        grid.rows.first { $0.locale == locale }?.cells.first { $0.key.field == field }
    }

    // MARK: - The sample grid

    @Test func sampleSummaryMatchesTheDesign() {
        let summary = StorePageSampleData.listing.coverage.summary
        #expect(summary.line == "10 of 39 locales · 11 missing · 1 over the limit · 1 machine-translated · 1 not pushed")
        #expect(summary.cellCount == 90)
        #expect(summary.filledCount == 79)
        #expect(summary.completenessPercent == 88)
    }

    @Test func sampleGridShape() {
        let grid = StorePageSampleData.listing.coverage
        #expect(grid.rows.count == 10)
        #expect(grid.rows.first?.locale == .englishUS)
        #expect(grid.rows.first?.isPrimary == true)
        #expect(grid.rows.dropFirst().allSatisfy { !$0.isPrimary })
        #expect(grid.fields == ListingField.allCases)
        #expect(grid.fields(at: .app) == [.name, .subtitle, .privacyPolicyURL])
        #expect(grid.rows.allSatisfy { $0.cells.count == 9 })
    }

    @Test func sampleCellTexts() {
        let grid = StorePageSampleData.listing.coverage
        #expect(cell(grid, .german, .subtitle)?.text == "31/30")
        #expect(cell(grid, .german, .name)?.text == "15/30")
        #expect(cell(grid, .japanese, .keywords)?.text == "MT")
        #expect(cell(grid, .french, .promotionalText)?.text == "Edited")
        #expect(cell(grid, .englishUS, .keywords)?.text == "88 B")
        #expect(cell(grid, .englishUS, .supportURL)?.text == "")
        #expect(cell(grid, .german, .subtitle)?.accessibilityLabel == "German, Subtitle: over the limit")
        #expect(cell(grid, .japanese, .keywords)?.accessibilityLabel == "Japanese, Keywords: machine-translated, not reviewed")
    }

    // MARK: - States

    @Test func problemsComeFirst() {
        var draft = ListingFieldDraft()
        draft.acceptMachineTranslation(String(repeating: "x", count: 31))
        let state = ListingCoverageState(draft: draft, field: .subtitle, isEditable: true)
        #expect(state == .overLimit(count: 31, limit: ListingTextLimit(30)))
        #expect(state.isProblem)

        var url = ListingFieldDraft()
        url.acceptMachineTranslation("lumen.example")
        #expect(ListingCoverageState(draft: url, field: .supportURL, isEditable: true) == .invalidURL)
    }

    @Test func proposedBeatsMachineTranslatedBeatsEdited() {
        var proposed = ListingFieldDraft(remote: "A", isMachineTranslated: true)
        _ = proposed.propose("B", by: Fixtures.client)
        #expect(ListingCoverageState(draft: proposed, field: .name, isEditable: true) == .proposed(client: Fixtures.client))

        var translated = ListingFieldDraft()
        translated.acceptMachineTranslation("B")
        #expect(ListingCoverageState(draft: translated, field: .name, isEditable: true) == .machineTranslated)

        var edited = ListingFieldDraft(remote: "A")
        edited.edit("")
        let state = ListingCoverageState(draft: edited, field: .name, isEditable: true)
        #expect(state == .edited)
        #expect(state.isNotPushed)
    }

    @Test func untouchedFieldsAreFilledOrMissing() {
        let filled = ListingCoverageState(draft: ListingFieldDraft(remote: "Lumen"), field: .name, isEditable: true)
        #expect(filled == .filled(count: 5))
        #expect(ListingCoverageState(draft: ListingFieldDraft(), field: .name, isEditable: true) == .missing)
        let keywords = ListingCoverageState(draft: ListingFieldDraft(remote: "café"), field: .keywords, isEditable: true)
        #expect(keywords == .filled(count: 5))
    }

    @Test func readOnlyCellsAreOnlyFilledOrMissing() {
        let draft = ListingFieldDraft(remote: String(repeating: "x", count: 40), isMachineTranslated: true)
        #expect(ListingCoverageState(draft: draft, field: .subtitle, isEditable: false) == .filled(count: 40))
        #expect(ListingCoverageState(draft: ListingFieldDraft(), field: .whatsNew, isEditable: false) == .missing)
    }

    @Test func liveVersionsStillShowAppInformationEdits() {
        var listing = StorePageSampleData.liveListing
        listing.edit(.name, in: .german, to: "Lumen")
        #expect(listing.coverageState(of: .name, in: .german) == .edited)
        #expect(listing.coverageState(of: .whatsNew, in: .german) == .missing)
        #expect(listing.coverageState(of: .whatsNew, in: .englishUS) != .missing)
    }

    @Test func firstVersionsHaveNoWhatsNewColumn() {
        let listing = Fixtures.listing(version: Fixtures.firstVersion)
        let grid = listing.coverage
        #expect(!grid.fields.contains(.whatsNew))
        #expect(grid.summary.cellCount == 16)
        let state = listing.coverageState(of: .whatsNew, in: .german)
        #expect(state == .notApplicable)
        #expect(ListingCoverageCell(key: Fixtures.key(.german, .whatsNew), state: state).text == "—")
    }

    // MARK: - Summary

    @Test func invalidURLsCountAsProblems() {
        var listing = Fixtures.listing()
        listing.edit(.supportURL, in: .german, to: "lumen.example/support")
        let summary = listing.coverage.summary
        #expect(summary.overLimitCount == 1)
        #expect(summary.localeCount == 2)
        #expect(summary.missingCount == 5)
        #expect(summary.notPushedCount == 0)
        #expect(summary.line == "2 of 39 locales · 5 missing · 1 over the limit · 0 machine-translated · 0 not pushed")
    }

    @Test func completenessCountsCellsWithText() {
        let summary = Fixtures.listing().coverage.summary
        #expect(summary.cellCount == 18)
        #expect(summary.filledCount == 12)
        #expect(summary.completenessPercent == 67)
        #expect(ListingCoverageSummary().completeness == 0)
    }
}
