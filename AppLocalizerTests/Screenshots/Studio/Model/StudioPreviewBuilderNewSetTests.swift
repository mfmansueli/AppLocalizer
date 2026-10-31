//
//  StudioPreviewBuilderNewSetTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The New preview: the set waiting in Review & Push, its chips, and when
/// New falls back to Live.
@MainActor
@Suite("StudioPreviewBuilder · New set")
struct StudioPreviewBuilderNewSetTests {
    @Test func renderedButNotPushedIsANewSet() {
        let builder = StudioTestFixtures.builder(choice: .new)
        #expect(builder.hasNewSet)
        #expect(builder.effectiveChoice == .new)
    }

    @Test func withoutATemplateNewShowsLive() {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.matrix = ScreenshotsTestFixtures.matrix(ScreenshotsDebugDocuments.document(for: .noTemplate))
        #expect(!builder.hasNewSet)
        #expect(builder.effectiveChoice == .live)
        #expect(builder.preview().note.hasPrefix("Live now"))
    }

    @Test func withEverythingPushedNewShowsLive() {
        var builder = StudioTestFixtures.builder(choice: .new)
        for (key, cell) in builder.matrix.cells where cell.state.isPending {
            builder.matrix.cells[key]?.state = .live
        }
        #expect(builder.matrix.hasTemplate)
        #expect(!builder.hasNewSet)
        #expect(builder.effectiveChoice == .live)
    }

    @Test func aLocalizedLanguageShowsItsNewScreenshots() throws {
        let preview = StudioTestFixtures.builder(locale: "ar-SA", choice: .new).preview()
        let name = try #require(StudioTestFixtures.templateName)
        #expect(preview.shots.count == 5)
        #expect(preview.shots.allSatisfy { $0.chip == .new })
        #expect(preview.note == "New set · \(name) · not pushed")
        #expect(preview.searchNote == "The new headlines, at the size search results show them.")
        #expect(preview.isRightToLeft)
    }

    @Test func screenshotsAlreadyLiveHaveNoChip() {
        let preview = StudioTestFixtures.builder(choice: .new).preview()
        #expect(preview.shots.count == 5)
        #expect(preview.shots.allSatisfy { $0.chip == nil })
        #expect(preview.shots.allSatisfy { $0.image.renderJob != nil })
    }

    @Test func anUnlocalizedLanguageShowsThePrimaryLanguagesNewSet() {
        let preview = StudioTestFixtures.builder(locale: "sv", choice: .new).preview()
        let english = StudioTestFixtures.matrix.row(locale: "en-US", displayType: .iPhone)
        #expect(preview.shots.map(\.image) == english.map(\.image))
        #expect(preview.shots.allSatisfy { $0.chip == .fallback(language: "English") })
        #expect(preview.note.hasPrefix("New set · "))
        #expect(preview.note.hasSuffix(" · not pushed · English until this language is localized"))
    }

    @Test func aCaptionTheAssistantShortenedIsMarked() {
        var builder = StudioTestFixtures.builder(locale: "de-DE", choice: .new)
        builder.run = StudioDebugRuns.run(.ready)
        let chips = builder.preview().shots.map(\.chip)
        #expect(chips == [nil, nil, .shortened, nil, nil])
    }

    @Test func aReadyRunNamesTheSetAfterItsDirection() {
        var builder = StudioTestFixtures.builder(locale: "ar-SA", choice: .new)
        builder.run = StudioDebugRuns.run(.ready)
        #expect(builder.newSetName == "Quiet Indigo")
        #expect(builder.preview().note == "New set · Quiet Indigo · not pushed")
    }

    @Test func aRunStillLocalizingKeepsTheTemplatesName() {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.run = StudioDebugRuns.run(.localize)
        #expect(builder.newSetName == StudioTestFixtures.templateName)
        builder.templateName = nil
        builder.run = nil
        #expect(builder.newSetName == nil)
        #expect(builder.preview().note == "New set · not pushed")
    }

    @Test func iPadUsesItsOwnCanvas() {
        let preview = StudioTestFixtures.builder(displayType: .iPad, choice: .new).preview()
        let cells = StudioTestFixtures.matrix.row(locale: "en-US", displayType: .iPad)
        #expect(preview.displayType == .iPad)
        #expect(preview.shots.map(\.pixelSize) == cells.map { $0.layout?.canvas.pixelSize ?? .init(width: 0, height: 0) })
        #expect(preview.searchShots.count == 2)
    }

    @Test func iPadWithoutIPadCellsFallsBackToIPhone() {
        var builder = StudioTestFixtures.builder(displayType: .iPad, choice: .new)
        builder.matrix.cells = builder.matrix.cells.filter { $0.key.displayType == .iPhone }
        let preview = builder.preview()
        #expect(preview.displayType == .iPhone)
        #expect(preview.shots.count == 5)
    }
}
#endif
