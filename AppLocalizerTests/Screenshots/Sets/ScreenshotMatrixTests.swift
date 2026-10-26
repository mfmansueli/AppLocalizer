//
//  ScreenshotMatrixTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Sets matrix built from the design's sample documents.
@MainActor
@Suite("ScreenshotMatrix")
struct ScreenshotMatrixTests {
    @Test func theStandardDocumentMatchesTheDesign() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        #expect(matrix.slotCount == 5)
        #expect(matrix.localizedLocales.count == 12)
        #expect(matrix.localizedLocales.first == "en-US")
        #expect(matrix.pendingCount == 40)
        #expect(matrix.failedCells.count == 2)
        #expect(matrix.overflowingCaptionCount(on: .iPhone) == 1)
        #expect(matrix.fallbackLocales.count == StoreLocaleCatalog.all.count - 12)
    }

    @Test func theFirstFailureIsGermanSlotThree() throws {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        let first = try #require(matrix.failedCells.first)
        #expect(first.key == ScreenshotCellKey(locale: "de-DE", displayType: .iPhone, slot: 2))
        #expect(first.state == .failed(reason: "Overflow"))
    }

    @Test func liveCellsMatchingWhatWasPushedAreLive() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        #expect(matrix.row(locale: "en-US", displayType: .iPhone).allSatisfy { $0.state == .live })
        #expect(matrix.row(locale: "ar-SA", displayType: .iPhone).allSatisfy { $0.state == .notPushed })
    }

    @Test func dutchShowsTheEnglishInterface() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        let row = matrix.row(locale: "nl-NL", displayType: .iPhone)
        let showsEnglish = row.allSatisfy(\.showsPrimaryInterface)
        #expect(showsEnglish)
        #expect(ScreenshotRowSummary(cells: row, restoredOn: nil).text == "5 not pushed · UI not localized")
    }

    @Test func fallbackLocalesShowThePrimarySet() throws {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        let cell = try #require(matrix.cell(locale: "da", displayType: .iPhone, slot: 0))
        #expect(cell.state == .fallback)
    }

    @Test func theFailedChecksDocumentMatchesTheDesign() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.failedChecks)
        #expect(matrix.localizedLocales.count == 14)
        #expect(matrix.failedCells.count == 23)
        #expect(matrix.pendingCount == 117)
    }

    @Test func thaiFailsForMissingGlyphsAndKoreanForTheWrongSize() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.failedChecks)
        #expect(matrix.cell(locale: "th", displayType: .iPhone, slot: 0)?.state == .failed(reason: "Missing glyphs"))
        #expect(matrix.cell(locale: "ko", displayType: .iPhone, slot: 3)?.state == .failed(reason: "Wrong size"))
    }

    @Test func renderJobsComeOncePerKeyPrimaryFirst() {
        let matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.standard)
        let jobs = matrix.renderJobs
        #expect(Set(jobs.map(\.key)).count == jobs.count)
        #expect(jobs.first?.layout.locale == "en-US")
    }

    @Test func anEmptyDocumentHasNoRows() {
        let matrix = ScreenshotsTestFixtures.matrix(.empty(primary: "en-US"))
        #expect(!matrix.hasCaptures)
        #expect(!matrix.hasTemplate)
        #expect(matrix.pendingCount == 0)
    }
}
#endif
