//
//  ScreenshotsViewerAndScopeTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The full-size viewer steps through the localized sets; the Locale Scope
/// sheet edits a draft that Save commits.
@MainActor
@Suite("Screenshots viewer and scope")
struct ScreenshotsViewerAndScopeTests {
    @Test func theViewerOpensOnArabicSlotOne() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "ar-SA", displayType: .iPhone, slot: 0))
        let target = try #require(model.viewer)
        #expect(model.viewerTitle(target) == "Slot 1 · Today")
        #expect(model.viewerPosition(target) == "2 of 12")
        #expect(model.viewerSubtitle == "iPhone 6.9″ · 1320 × 2868 px · steps through the 12 localized sets")
        #expect(model.viewerCell(target)?.state == .notPushed)
    }

    @Test func germanSlotThreeIsSixthAndFails() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "de-DE", displayType: .iPhone, slot: 2))
        let target = try #require(model.viewer)
        #expect(model.viewerPosition(target) == "6 of 12")
        let cell = try #require(model.viewerCell(target))
        #expect(cell.checks.map(\.status) == [.passed, .passed, .failed])
        #expect(cell.layout?.headline.label == "1 line too many at 80 u")
    }

    @Test func steppingWrapsAround() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "en-US", displayType: .iPhone, slot: 1))
        model.stepViewer(by: -1)
        let last = try #require(model.viewer)
        #expect(model.viewerPosition(last) == "12 of 12")
        #expect(last.slot == 1)
        model.stepViewer(by: 1)
        #expect(model.viewer?.locale == "en-US")
    }

    @Test func openingAnIPadCellSwitchesTheDisplayType() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "fr-FR", displayType: .iPad, slot: 0))
        #expect(model.displayType == .iPad)
        #expect(model.viewerImageWidth == 600)
    }

    @Test func editCaptionAndTemplateEditorCloseTheViewer() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "fr-FR", displayType: .iPhone, slot: 0))
        model.editCaption()
        #expect(model.viewer == nil)
        #expect(model.tab == .captions)
        model.openViewer(ScreenshotCellKey(locale: "fr-FR", displayType: .iPhone, slot: 0))
        model.openTemplateEditor()
        #expect(model.tab == .template)
    }

    @Test func theScopeSheetListsEveryLocaleWithItsState() async throws {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openScope()
        let rows = model.scopeRows
        #expect(rows.count == 39)
        let english = try #require(rows.first { $0.locale.code == "en-US" })
        #expect(english.isPrimary)
        #expect(english.isIncluded)
        #expect(english.live == .localizedSet)
        let british = try #require(rows.first { $0.locale.code == "en-GB" })
        #expect(british.live == .uploadedByHand)
        let arabic = try #require(rows.first { $0.locale.code == "ar-SA" })
        #expect(arabic.captionsTitle == "5 of 5")
        #expect(arabic.capturesTitle == "Own interface")
        #expect(arabic.liveTitle(primaryName: "English (U.S.)") == "Uses English (U.S.)")
        #expect(model.scopeEstimate.hasPrefix("12 locales × 5 slots × 2 display types = 120 images · about 600 requests"))
    }

    @Test func savingTheScopeCommitsAndRebuilds() async throws {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        model.openScope()
        model.setScope("da", included: true)
        await model.saveScope()
        #expect(model.scopeDraft == nil)
        let saved = try #require(services.saved.last)
        #expect(saved.scope.contains("da"))
        #expect(model.scopeTitle == "13 of 39 locales localized")
        #expect(model.matrix.localizedLocales.contains("da"))
    }

    @Test func cancellingLeavesTheScopeAlone() async {
        let (model, services) = await ScreenshotsTestFixtures.viewModel()
        model.openScope()
        model.selectAllLocales()
        #expect(model.scopeEstimate.hasPrefix("39 locales"))
        model.scopeDraft = nil
        #expect(services.saved.isEmpty)
        #expect(model.scopeTitle == "12 of 39 locales localized")
    }

    @Test func onlyThePrimaryShortcutLeavesOne() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openScope()
        model.selectOnlyPrimary()
        #expect(model.scopeDraft?.count == 1)
        model.selectLocalesWithCaptures()
        #expect(model.scopeDraft?.contains("ar-SA") == true)
        #expect(model.scopeDraft?.contains("nl-NL") == false)
    }
}
#endif
