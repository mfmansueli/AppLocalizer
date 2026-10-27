//
//  CaptureCoverageTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("CaptureCoverage")
struct CaptureCoverageTests {
    private func coverage(_ document: ScreenshotsDocument, display: ScreenshotDisplayType = .iPhone) -> CaptureCoverage {
        CaptureCoverage.make(CaptureCoverage.Inputs(document: document, displayType: display, primary: .englishUS, locales: StoreLocaleCatalog.all))
    }

    @Test func labelsEachLocalesCapturesAndSource() throws {
        let coverage = coverage(ScreenshotsDebugDocuments.standard)
        let localized = try #require(coverage.groups.first)
        #expect(localized.title == "Localized sets")
        #expect(localized.rows.count == 12)
        #expect(localized.rows.first?.locale == .englishUS)
        #expect(localized.rows.dropFirst().first?.locale.code == "ar-SA")

        let german = try #require(localized.rows.first { $0.locale.code == "de-DE" })
        #expect(german.sourceText == "fastlane · own")
        #expect(german.cells.allSatisfy { $0.label == .localized })

        let dutch = try #require(localized.rows.first { $0.locale.code == "nl-NL" })
        #expect(dutch.sourceText == "English (U.S.)")
        #expect(dutch.cells.allSatisfy { $0.label == .primaryInterface(language: "English") })
        #expect(dutch.cells.first?.label.title == "English UI")
        #expect(coverage.legend == "English (U.S.) capture used, interface not localized")
        #expect(coverage.slotNames == ["Today", "Week", "Search", "Photos", "Privacy"])
    }

    @Test func summarizesTheImport() {
        #expect(coverage(ScreenshotsDebugDocuments.standard).summary == "70 captures · fastlane · imported Oct 26 · 10 locales have their own iPhone interface")
        #expect(coverage(ScreenshotsDebugDocuments.standard, display: .iPad).summary.hasSuffix("4 locales have their own iPad interface"))
    }

    @Test func anIPadCaptureInAnIPhoneSlotIsTheWrongSize() throws {
        let coverage = coverage(ScreenshotsDebugDocuments.thaiAndVietnamese)
        let korean = try #require(coverage.groups.first?.rows.first { $0.locale.code == "ko" })
        #expect(korean.cells[3].label == .wrongSize)
        #expect(korean.cells[3].label.title == "Wrong size")
        #expect(korean.cells[0].label == .localized)
    }

    @Test func capturedLocalesOutsideTheScopeAreListedApart() throws {
        var document = ScreenshotsDebugDocuments.standard
        document.scope.set("ja", included: false)
        let coverage = coverage(document)
        #expect(coverage.groups.count == 2)
        let others = try #require(coverage.groups.last)
        #expect(others.rows.map(\.locale.code) == ["ja"])
    }

    @Test func aSlotWithoutAnyCaptureIsMissing() throws {
        var document = ScreenshotsDocument.empty(primary: "en-US")
        document.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 0))
        let row = try #require(coverage(document).groups.first?.rows.first)
        #expect(row.cells.count == 1)
        document.slotNames = ["Today", "Week"]
        document.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 1))
        document.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPad, slot: 1))
        let iPad = try #require(coverage(document, display: .iPad).groups.first?.rows.first)
        #expect(iPad.cells.map(\.label) == [.missing, .localized])
    }
}
