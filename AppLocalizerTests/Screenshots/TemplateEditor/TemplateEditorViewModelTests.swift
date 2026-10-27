//
//  TemplateEditorViewModelTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Template tab's edits: the applier's refusals, the draft and its
/// undo, saving as the next version, restoring and switching starters.
@MainActor
@Suite("TemplateEditorViewModel")
struct TemplateEditorViewModelTests {
    /// The Screenshots view model and its fakes; the editor is reached
    /// through the view model, which owns it.
    @MainActor
    struct Screen {
        let model: ScreenshotsViewModel
        let services: FakeScreenshotsServices

        var editor: TemplateEditorViewModel { model.templateEditor }
    }

    /// The Template tab on German slot 3.
    private func makeScreen(_ document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard) async -> Screen {
        let (model, services) = await ScreenshotsTestFixtures.viewModel(document)
        model.openTemplateEditor(at: LocaleSlot(locale: "de-DE", slot: 2))
        return Screen(model: model, services: services)
    }

    @Test func anEditIsADraftUntilSavedAsTheNextVersion() async {
        let screen = await makeScreen()
        #expect(screen.editor.versionTitle == "v4")
        #expect(screen.editor.set("fit.hyphenate", to: true))
        #expect(screen.editor.hasUnsavedEdits)
        #expect(screen.editor.saveTitle == "Save as v5")
        #expect(screen.editor.draftSummary == "Hyphenate long words on")
        #expect(screen.editor.savedTemplate?.fit.hyphenate == false)

        await screen.editor.save()
        #expect(!screen.editor.hasUnsavedEdits)
        #expect(screen.editor.versionTitle == "v5")
        #expect(screen.editor.history?.current?.note == "Hyphenate long words on")
        #expect(screen.editor.history?.current?.author == .you)
        #expect(screen.services.storedDocument?.template?.fit.hyphenate == true)
    }

    @Test func aRefusedEditLeavesTheTemplateAndSaysWhy() async throws {
        let screen = await makeScreen()
        #expect(!screen.editor.set("caption.headline.maxLines", to: 7))
        let refusal = try #require(screen.editor.refusals?.items.first)
        #expect(refusal.kind == .outOfRange)
        #expect(refusal.reason.contains("7"))
        #expect(!screen.editor.hasUnsavedEdits)
        #expect(screen.editor.set("caption.headline.maxLines", to: 3))
        #expect(screen.editor.refusals == nil)
    }

    @Test func theSmallestSizeCantPassTheSize() async {
        let screen = await makeScreen()
        screen.editor.setHeadlineSize(72)
        #expect(screen.editor.template?.caption.headline.size == 72)
        #expect(screen.editor.template?.caption.headline.min == 72)
        #expect(screen.editor.refusals == nil)
        #expect(!screen.editor.set("caption.headline.min", to: 100))
        #expect(screen.editor.refusals?.items.first?.kind == .inconsistent)
    }

    @Test func aSliderDragIsOneUndoStep() async {
        let screen = await makeScreen()
        for size in [110.0, 108, 106] {
            screen.editor.setHeadlineSize(size)
        }
        screen.editor.set("fit.hyphenate", to: true)
        #expect(screen.editor.undoStack.count == 2)
        screen.editor.undo()
        #expect(screen.editor.template?.fit.hyphenate == false)
        #expect(screen.editor.template?.caption.headline.size == 106)
        screen.editor.undo()
        #expect(!screen.editor.hasUnsavedEdits)
        #expect(screen.editor.template?.caption.headline.size == 112)
        #expect(!screen.editor.canUndo)
    }

    @Test func editingBackToTheSavedValuesIsNoEdit() async {
        let screen = await makeScreen()
        screen.editor.setHeadlineSize(104)
        #expect(screen.editor.hasUnsavedEdits)
        screen.editor.setHeadlineSize(112)
        #expect(!screen.editor.hasUnsavedEdits)
    }

    @Test func slotOverridesAreListedAndClearable() async throws {
        let screen = await makeScreen()
        screen.editor.focus(on: LocaleSlot(locale: "en-US", slot: 1))
        let override = try #require(screen.editor.slotOverrides.first)
        #expect(screen.editor.slotOverrides.count == 1)
        #expect(override.title == "Slot 2 headline size")
        #expect(override.newText == "104 u")
        #expect(screen.editor.slotHeadlineSize == 104)

        screen.editor.clearOverride(override)
        #expect(screen.editor.slotOverrides.isEmpty)
        #expect(screen.editor.slotHeadlineSize == 112)
        #expect(screen.editor.draftSummary == "Slot 2 headline size as the template")
    }

    @Test func theTemplatesSizeClearsASlotOverrideAndResetClearsThemAll() async {
        let screen = await makeScreen()
        screen.editor.setSlotHeadlineSize(96)
        screen.editor.set("slots.2.over.caption.align", to: "start")
        #expect(screen.editor.slotOverrides.map(\.fieldPath) == ["caption.align", "caption.headline.size"])
        screen.editor.setSlotHeadlineSize(112)
        #expect(screen.editor.slotOverrides.map(\.fieldPath) == ["caption.align"])
        screen.editor.resetSlot()
        #expect(screen.editor.slotOverrides.isEmpty)
        #expect(!screen.editor.hasUnsavedEdits)
    }

    @Test func restoringMakesANewVersionFromTheOldOne() async {
        let screen = await makeScreen()
        screen.editor.set("fit.hyphenate", to: true)
        await screen.editor.restore(3)
        #expect(!screen.editor.hasUnsavedEdits)
        #expect(screen.editor.versionTitle == "v5")
        #expect(screen.editor.history?.versions.count == 5)
        #expect(screen.editor.history?.current?.restoredFrom == 3)
        #expect(screen.editor.template?.rightToLeft.mirror == false)
        #expect(screen.editor.historyRows.first?.isCurrent == true)
        #expect(screen.editor.historyRows.last?.canRestore == true)
    }

    @Test func historyRowsNoteThePushedVersion() async {
        let screen = await makeScreen()
        let rows = screen.editor.historyRows
        #expect(rows.map(\.number) == [4, 3, 2, 1])
        #expect(rows[0].note.hasPrefix("Arabic and Hebrew mirror the layout · pushed "))
        #expect(rows[1].note == "Headline 112 u, smallest 80 u")
        #expect(rows[0].isCurrent && !rows[0].canRestore)
        #expect(rows[1].detail.hasSuffix("· You"))
    }

    @Test func switchingStartersKeepsCaptionsAndCaptures() async throws {
        let screen = await makeScreen()
        let before = try #require(screen.model.document)
        #expect(screen.editor.starterButtonTitle(.above) == "Start Over from This")
        #expect(screen.editor.starterButtonTitle(.panorama) == "Switch to This")
        screen.editor.isStarterSheetPresented = true

        await screen.editor.switchStarter(.panorama)
        let after = try #require(screen.model.document)
        #expect(!screen.editor.isStarterSheetPresented)
        #expect(after.template?.starter == .panorama)
        #expect(after.template?.name == "Lumen · Panorama")
        #expect(after.history?.currentNumber == 5)
        #expect(after.history?.current?.note == "Switched to the starter “Panorama”")
        #expect(after.captions == before.captions)
        #expect(after.captures == before.captures)
        #expect(screen.editor.starterSheetNote.hasPrefix("Switching keeps Lumen’s captions and captures"))
    }

    @Test func openInTemplateEditorLandsOnTheViewersLocaleAndSlot() async {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openViewer(ScreenshotCellKey(locale: "ar-SA", displayType: .iPhone, slot: 1))
        model.openTemplateEditor()
        #expect(model.viewer == nil)
        #expect(model.tab == .template)
        #expect(model.templateEditor.localeCode == "ar-SA")
        #expect(model.templateEditor.slot == 1)
        #expect(model.templateEditor.slotTitles[1] == "2 Week")
    }

    @Test func thePreviewsShowTheOverflowAndTheStressLocales() async throws {
        let screen = await makeScreen()
        screen.editor.refreshPreviews()
        let canvas = try #require(screen.editor.canvas)
        #expect(canvas.fit.tone == .overflows)
        #expect(canvas.fit.label == "1 line too many at 80 u")
        #expect(screen.editor.strip.map(\.locale.code) == ["en-US", "de-DE", "ar-SA", "ja"])
        #expect(screen.editor.strip.map(\.role) == [.primary, .longest, .rightToLeft, .cjk])
    }

    @Test func anUntranslatedStressLocaleGetsAPreviewTranslation() async {
        let screen = await makeScreen()
        screen.services.translator = CannedCaptionTranslator(answers: ["fi": "Hae vuosien merkinnöistä sekunneissa ilman mitään vaivaa tänään"])
        screen.editor.refreshPreviews()
        let arrived = await ScreenshotsTestWaiting.until { screen.editor.previewCaptions[LocaleSlot(locale: "fi", slot: 2)] != nil }
        #expect(arrived)
        screen.editor.refreshPreviews()
        #expect(screen.editor.strip.contains { $0.locale.code == "fi" || $0.locale.code == "de-DE" })
        #expect(screen.editor.previewCaptions[LocaleSlot(locale: "fi", slot: 2)]?.provenance == .machineTranslated)
        #expect(screen.services.storedDocument?.captions.caption(locale: "fi", slot: 2) == nil)
    }

    @Test func theFontRowsFlagAScriptNothingDraws() async throws {
        let screen = await makeScreen(ScreenshotsDebugDocuments.failedChecks)
        let thai = try #require(screen.editor.fontRows.first { $0.script == .thai })
        #expect(thai.hasProblem)
        #expect(thai.problemText == "1 locale fails")
        #expect(thai.status == "No font for this script")
        let latin = try #require(screen.editor.fontRows.first { $0.script == .latin })
        #expect(!latin.hasProblem)
        #expect(screen.editor.fontTitle("Northpier Display") == "Northpier Display")
    }

    @Test func aFallbackThatCantDrawTheScriptIsRefused() async {
        let screen = await makeScreen(ScreenshotsDebugDocuments.failedChecks)
        screen.editor.setFallback("Hiragino Sans", for: .thai)
        #expect(screen.editor.refusals?.items.first?.kind == .fontCantDrawScript)
        screen.editor.setFallback("Thonburi", for: .thai)
        #expect(screen.editor.refusals == nil)
        #expect(screen.editor.fontRows.first { $0.script == .thai }?.hasProblem == false)
    }
}
#endif
