//
//  TemplateStyleLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The gallery's looks laid out: a caption below the device, uppercase by
/// each language's rules, an emphasized line and highlight bars after
/// wrapping, decorations and angles mirrored right to left.
@MainActor
@Suite("Template style layout")
struct TemplateStyleLayoutTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private static let longHeadline = "Write a little every day and watch your whole year take shape"

    private func layout(
        _ template: ScreenshotTemplate, slot: Int = 0, locale: StoreLocale = .englishUS, display: ScreenshotDisplayType = .iPhone,
        headline: String = "Your days, kept"
    ) -> ScreenshotLayout {
        engine.layout(template, slot: slot, locale: locale, displayType: display, caption: ScreenshotCaption(headline: headline))
    }

    private func starter(_ starter: TemplateStarter) -> ScreenshotTemplate {
        ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
    }

    @Test func aCaptionBelowSitsUnderTheLeaningDevice() throws {
        let result = layout(starter(.cinema))
        let device = try #require(result.device)
        #expect(device.frame.maxY < result.captionBox.minY)
        #expect(result.captionBox.maxY <= result.canvas.height * (1 - ScreenshotLayoutEngine.belowMinimumBottom) + 0.5)
        #expect(device.tilt != nil)
    }

    @Test func uppercaseFollowsTheLanguage() {
        var template = starter(.above)
        template.caption.headline.uppercase = true
        let turkish = layout(template, locale: .turkish, headline: "istanbul")
        #expect(turkish.lines.map(\.text).joined() == "İSTANBUL")
        let german = layout(template, locale: .german, headline: "Straße")
        #expect(german.lines.map(\.text).joined() == "STRASSE")
        let english = layout(template, headline: "istanbul")
        #expect(english.lines.map(\.text).joined() == "ISTANBUL")
    }

    @Test func theLastLineIsEmphasizedAfterWrapping() throws {
        var template = starter(.above)
        template.caption.headline.weight = 500
        template.caption.headline.emphasis = TemplateEmphasis(line: .last, weight: 800)
        let lines = layout(template, headline: Self.longHeadline).lines
        try #require(lines.count >= 2)
        #expect(lines.last?.weight == 800)
        #expect(lines.dropLast().allSatisfy { $0.weight == 500 })
    }

    @Test func anItalicEmphasisSlantsOnlyItsLine() throws {
        var template = starter(.above)
        template.caption.headline.emphasis = TemplateEmphasis(line: .first, italic: true)
        let lines = layout(template, headline: Self.longHeadline).lines
        try #require(lines.count >= 2)
        #expect(lines.first?.isItalic == true)
        #expect(lines.dropFirst().allSatisfy { !$0.isItalic })
    }

    @Test func highlightBarsAlternateAndNarrowTheBox() throws {
        var template = starter(.above)
        template.caption.headline.highlight = TemplateHighlight(color: "#CFAEFF", padding: 0.2, rotation: -2, radius: 0.05)
        let marked = layout(template, headline: Self.longHeadline)
        try #require(marked.lines.count >= 2)
        #expect(marked.lines.allSatisfy { $0.highlight != nil })
        #expect(marked.lines[0].highlight?.rotation == -2)
        #expect(marked.lines[1].highlight?.rotation == 2)
        let padding = try #require(marked.lines[0].highlight?.padding)
        #expect(abs(padding - 0.2 * marked.lines[0].pixelSize) < 0.01)
        // The same one-line headline fills more of the narrower box.
        let plainShort = layout(starter(.above)).headline
        let markedShort = layout(template).headline
        #expect(plainShort.lines == markedShort.lines)
        #expect(markedShort.fill > plainShort.fill, "Room for the bars' padding")
    }

    @Test func decorationsAndAnglesMirrorRightToLeft() throws {
        let template = starter(.sparkle)
        let english = layout(template, slot: 1)
        let arabic = layout(template, slot: 1, locale: .arabic)
        let width = english.canvas.width
        let sparkle = try #require(english.decorations.first)
        let mirrored = try #require(arabic.decorations.first)
        #expect(sparkle.frame.midX > width / 2)
        #expect(abs(mirrored.frame.midX - (width - sparkle.frame.midX)) < 1)
        #expect(mirrored.isFlipped)
        let tilt = try #require(english.device?.tilt)
        let arabicTilt = try #require(arabic.device?.tilt)
        #expect(arabicTilt.rotate == -tilt.rotate)
    }

    @Test func backDecorationsAndFrontOnesAreLayered() {
        let playful = layout(starter(.playful), slot: 3)
        #expect(playful.decorations.contains { !$0.isFront && $0.kind == .shape })
        #expect(playful.decorations.contains { $0.isFront && $0.kind == .laurel && $0.ratingValue == 4.5 })
    }

    @Test func aTiltedLandscapeDeviceClearsTheCaption() throws {
        var flat = starter(.above)
        flat.canvas.ipad = .landscape
        var tilted = flat
        tilted.device.tilt = TemplateTilt(rotate: 10, turn: 0, lean: 0)
        let flatDevice = try #require(layout(flat, slot: 1, display: .iPad).device)
        let tiltedLayout = layout(tilted, slot: 1, display: .iPad)
        let tiltedDevice = try #require(tiltedLayout.device)
        #expect(tiltedDevice.frame.minY > flatDevice.frame.minY)
        let corners = [
            CGPoint(x: tiltedDevice.frame.minX, y: tiltedDevice.frame.minY), CGPoint(x: tiltedDevice.frame.maxX, y: tiltedDevice.frame.minY),
        ]
        let transform = try #require(tiltedDevice.tilt).transform
        for corner in corners {
            #expect(corner.applying(transform).y >= tiltedLayout.captionBox.maxY - 1)
        }
    }

    @Test func theSlotsShiftMovesTheDevice() throws {
        var template = starter(.above)
        let centered = try #require(layout(template, slot: 0).device)
        template.slots[0].over["device.dx"] = .double(0.1)
        let shifted = try #require(layout(template, slot: 0).device)
        #expect(abs(shifted.frame.midX - centered.frame.midX - 0.1 * 1320) < 1)
    }
}
