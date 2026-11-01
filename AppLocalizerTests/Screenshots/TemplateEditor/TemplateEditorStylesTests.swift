//
//  TemplateEditorStylesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The inspector's new rows: the slot's angle and own background, the
/// caption's color, uppercase, emphasis and highlight, and the slot's
/// decorations. Per-slot edits are overrides, cleared once they match the
/// template again.
@MainActor
@Suite("TemplateEditorViewModel styles")
struct TemplateEditorStylesTests {
    /// The Screenshots view model, which owns the screen.editor.
    @MainActor
    struct Screen {
        let model: ScreenshotsViewModel

        var editor: TemplateEditorViewModel { model.templateEditor }
    }

    /// The Template tab on German slot 3.
    private func makeScreen() async -> Screen {
        let (model, _) = await ScreenshotsTestFixtures.viewModel()
        model.openTemplateEditor(at: LocaleSlot(locale: "de-DE", slot: 2))
        return Screen(model: model)
    }

    @Test func theAngleIsTheSlotsOwn() async {
        let screen = await makeScreen()
        #expect(screen.editor.slotTilt == .flat)
        screen.editor.setSlotTilt(TemplateTilt(rotate: 8, turn: -12, lean: 6))
        #expect(screen.editor.template?.slots[2].over["device.tilt"] != nil)
        #expect(screen.editor.template?.device.tilt == nil, "Other slots stay flat")
        #expect(screen.editor.slotTilt == TemplateTilt(rotate: 8, turn: -12, lean: 6))
        screen.editor.setSlotTilt(.flat)
        #expect(screen.editor.template?.slots[2].over["device.tilt"] == nil, "Back to the template's angle clears the override")
    }

    @Test func aSlotGetsItsOwnBackgroundAndGivesItBack() async {
        let screen = await makeScreen()
        #expect(screen.editor.canGiveOwnBackground)
        #expect(!screen.editor.hasOwnBackground)
        screen.editor.giveSlotOwnBackground()
        #expect(screen.editor.hasOwnBackground)
        #expect(!screen.editor.canGiveOwnBackground)
        let templateStops = screen.editor.template?.background.stops
        screen.editor.setBackgroundStop(0, to: "#112233")
        #expect(screen.editor.effectiveBackground?.stops.first == "#112233")
        #expect(screen.editor.template?.background.stops == templateStops, "The colors edit the slot's background")
        screen.editor.setBackgroundKind(.solid)
        #expect(screen.editor.effectiveBackground?.kind == .solid)
        #expect(screen.editor.effectiveBackground?.stops.count == 1)
        screen.editor.useTemplateBackground()
        #expect(!screen.editor.hasOwnBackground)
        #expect(screen.editor.effectiveBackground == screen.editor.template?.background)
    }

    @Test func aPanoramaCantBeGivenToOneSlot() async {
        let screen = await makeScreen()
        screen.editor.setBackgroundKind(.panorama)
        #expect(!screen.editor.canGiveOwnBackground)
    }

    @Test func theColorEditsTheSlotsOverrideWhenItHasOne() async {
        let screen = await makeScreen()
        screen.editor.setInk("#101010")
        #expect(screen.editor.template?.caption.ink == "#101010")
        #expect(screen.editor.set("slots.2.over.caption.ink", to: "#FF0000"))
        screen.editor.setInk("#00FF00")
        #expect(screen.editor.slotInk == "#00FF00")
        #expect(screen.editor.template?.caption.ink == "#101010")
    }

    @Test func uppercaseAndHighlightTurnOnAndOff() async {
        let screen = await makeScreen()
        screen.editor.setUppercase(true)
        #expect(screen.editor.isUppercase)
        screen.editor.setUppercase(false)
        #expect(!screen.editor.isUppercase)
        #expect(screen.editor.template?.caption.headline.uppercase == nil, "Off leaves the field out")

        screen.editor.setHighlighted(true)
        #expect(screen.editor.highlight == TemplateEditorViewModel.defaultHighlight)
        screen.editor.setHighlightColor("#FFD25E")
        #expect(screen.editor.highlight?.color == "#FFD25E")
        screen.editor.setHighlighted(false)
        #expect(screen.editor.highlight == nil)
    }

    @Test func emphasisPicksALineAndHowItDiffers() async {
        let screen = await makeScreen()
        #expect(screen.editor.emphasisLine == nil)
        #expect(screen.editor.emphasisStyle == nil)
        screen.editor.setEmphasisLine(.last)
        #expect(screen.editor.emphasisLine == .last)
        // The Above starter's headline is bold, so the new emphasis is light.
        #expect(screen.editor.emphasisStyle == .light)
        screen.editor.setEmphasisStyle(.italic)
        #expect(screen.editor.emphasisStyle == .italic)
        screen.editor.setEmphasisStyle(.heavy)
        #expect(screen.editor.template?.caption.headline.emphasis == TemplateEmphasis(line: .last, weight: 800))
        screen.editor.setEmphasisLine(nil)
        #expect(screen.editor.template?.caption.headline.emphasis == nil)
    }

    @Test func lightPairsArchivoBlackWithArchivo() async {
        let screen = await makeScreen()
        screen.editor.setDisplayFont("Archivo Black")
        screen.editor.setEmphasisLine(.first)
        screen.editor.setEmphasisStyle(.light)
        #expect(screen.editor.template?.caption.headline.emphasis?.font == "Archivo")
    }

    @Test func decorationsAreAddedEditedAndRemovedOnTheSlot() async {
        let screen = await makeScreen()
        #expect(screen.editor.slotDecorations.isEmpty)
        #expect(screen.editor.decorationsTitle == "Decorations · Slot 3")
        screen.editor.addDecoration(.rating)
        screen.editor.addDecoration(.sparkle)
        #expect(screen.editor.slotDecorations.map(\.type) == [.laurel, .shape])
        #expect(screen.editor.slotDecorations[0].value == "4.8")
        #expect(screen.editor.slotDecorations[1].color == screen.editor.slotInk, "A sparkle takes the caption's color")
        #expect(screen.editor.template?.decorations == nil, "Only slot 3 has them")

        screen.editor.setDecorationValue(" 4.6 ", at: 0)
        #expect(screen.editor.slotDecorations[0].value == "4.6")
        screen.editor.setDecorationValue("Best", at: 0)
        #expect(screen.editor.slotDecorations[0].value == "4.6", "Letters are refused")
        #expect(screen.editor.refusals != nil)
        screen.editor.setDecorationColor("#FFD25E", at: 1)
        #expect(screen.editor.slotDecorations[1].color == "#FFD25E")

        screen.editor.removeDecoration(at: 0)
        screen.editor.removeDecoration(at: 0)
        #expect(screen.editor.slotDecorations.isEmpty)
        #expect(screen.editor.template?.slots[2].over["deco"] == nil, "No decorations again clears the override")
    }

    @Test func eachPresetIsAValidDecoration() async {
        let screen = await makeScreen()
        for preset in TemplateEditorViewModel.DecorationPreset.allCases {
            screen.editor.addDecoration(preset)
        }
        #expect(screen.editor.slotDecorations.count == 4)
        #expect(screen.editor.refusals == nil)
        #expect(screen.editor.slotDecorations.filter(\.isRating).count == 2)
        #expect(screen.editor.ratingNote.contains("Lumen’s App Store rating"))
    }
}
#endif
