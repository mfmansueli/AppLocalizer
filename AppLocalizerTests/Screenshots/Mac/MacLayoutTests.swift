//
//  MacLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A template laid out for Mac: the 2880 × 1800 canvas, a MacBook (its
/// base under the lid and wider) that stays on the canvas, and a
/// template's landscape overrides applied on Mac but not on a portrait
/// set.
@MainActor
@Suite("Mac layout")
struct MacLayoutTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
    private static let macBook = PixelSize(width: 2880, height: 1800)

    private func layout(
        _ template: ScreenshotTemplate, slot: Int = 0, display: ScreenshotDisplayType = .mac, captureSize: PixelSize? = macBook
    ) -> ScreenshotLayout {
        engine.layout(
            template, slot: slot, locale: .englishUS, displayType: display,
            caption: ScreenshotCaption(headline: "Write it down"), captureSize: display == .mac ? captureSize : nil
        )
    }

    // MARK: - The MacBook

    @Test(arguments: TemplateStarter.allCases)
    func everyTemplateLaysOutAMacBookOnTheCanvas(_ starter: TemplateStarter) throws {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        let result = layout(template)
        #expect(result.canvas.pixelSize == Self.macBook)
        guard template.device.show else { return }
        let device = try #require(result.device)
        let base = try #require(device.base, "A MacBook has its base")
        #expect(device.isLaptop)
        #expect(base.width > device.frame.width, "The base overhangs the lid")
        #expect(abs(base.midX - device.frame.midX) < 1)
        #expect(base.minY < device.frame.maxY && base.maxY > device.frame.maxY, "Under the lid")
        #expect(base.maxY <= result.canvas.height + 1, "\(starter): the base stays on the canvas")
    }

    @Test func theBaseIsAThinSlabUnderTheLid() {
        let lid = CGRect(x: 400, y: 300, width: 2000, height: 1300)
        let base = ScreenshotLayoutEngine.laptopBase(under: lid)
        #expect(abs(base.width - 2280) < 0.001, "7% past the lid each side")
        #expect(abs(base.minX - 260) < 0.001)
        #expect(abs(base.height - 1300 * ScreenshotLayoutEngine.laptopBaseHeight) < 0.001)
        #expect(base.minY < lid.maxY)
    }

    @Test func otherDevicesHaveNoBase() {
        for display in [ScreenshotDisplayType.iPhone, .iPad, .iPhoneDuo] {
            #expect(layout(arcade, display: display).device?.base == nil, "\(display.shortTitle)")
        }
    }

    @Test func anIPadCaptureStandingInStillGetsTheMacCanvas() {
        let result = layout(arcade, captureSize: PixelSize(width: 2752, height: 2064))
        #expect(result.canvas.pixelSize == Self.macBook)
        #expect(result.device?.isLaptop == true)
    }

    // MARK: - Landscape overrides

    @Test func arcadesLandscapeOverridesApplyOnlyOnALandscapeCanvas() {
        let portrait = arcade.resolved(forSlot: 0)
        let landscape = arcade.resolved(forSlot: 0, isLandscape: true)
        #expect(portrait.caption.headline.size == 143)
        #expect(landscape.caption.headline.size == 92)
        #expect(landscape.caption.headline.min == 64)
        #expect(portrait.device.top == 0.267)
        #expect(landscape.device.top == nil, "The MacBook follows the caption")
    }

    @Test func landscapeOverridesComeAfterTheSlots() {
        // Slot 3 shifts the phone right and pins it; landscape centers it.
        let slot = arcade.resolved(forSlot: 2)
        #expect(slot.device.shiftRight == 0.19)
        #expect(slot.device.top == 0.372)
        let landscape = arcade.resolved(forSlot: 2, isLandscape: true)
        #expect(landscape.device.shiftRight == 0)
        #expect(landscape.device.top == nil)
        #expect(landscape.device.pair?.shiftRight == -0.2)
        #expect(landscape.device.pair?.top == nil)
    }

    @Test func aTemplateWithoutLandscapeOverridesIsUnchanged() {
        var template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        template.landscape = nil
        #expect(template.resolved(forSlot: 0, isLandscape: true) == template.resolved(forSlot: 0))
    }

    @Test func overridesThatCantApplyAreIgnored() {
        var template = arcade
        template.landscape = ["slots": .array([]), "landscape": .null, "caption.headline.size": .string("big"), "device.dx": .double(0.1)]
        let resolved = template.resolved(forSlot: 0, isLandscape: true)
        #expect(resolved.caption.headline.size == 143, "A string isn't a size")
        #expect(resolved.device.shiftRight == 0.1)
        #expect(resolved.slots.count == arcade.slots.count)
    }

    @Test func theMacCaptionUsesTheLandscapeSize() throws {
        // Slot 2 isn't the hero, so its headline is the style's size.
        let mac = layout(arcade, slot: 1)
        let line = try #require(mac.lines.first)
        let size = line.pixelSize / mac.canvas.unit
        #expect(size <= 92.5, "At most the landscape size, in u: \(size)")
        #expect(size >= 63.5, "At least the landscape minimum, in u: \(size)")
    }

    @Test func theLandscapeOverridesSurviveJSON() throws {
        let data = try JSONEncoder().encode(arcade)
        let decoded = try JSONDecoder().decode(ScreenshotTemplate.self, from: data)
        #expect(decoded.landscape == arcade.landscape)
        #expect(decoded.landscape?["caption.headline.size"]?.doubleValue == 92)
    }
}
