//
//  ArcadeLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// What Arcade added to the layout engine: a device top that holds unless
/// the caption needs the room, a caption box sized to its lines, Two
/// phones, black empty screens, props anchored to the caption or stepping
/// aside from it, a figure across two slots, and a heavier fallback for
/// scripts Boldonse can't draw.
@MainActor
@Suite("Arcade layout")
struct ArcadeLayoutTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
    private static let longHeadline = "Win every single match tonight with friends"

    private func layout(
        _ template: ScreenshotTemplate, slot: Int = 0, locale: StoreLocale = .englishUS, display: ScreenshotDisplayType = .iPhone,
        headline: String = "Play"
    ) -> ScreenshotLayout {
        engine.layout(template, slot: slot, locale: locale, displayType: display, caption: ScreenshotCaption(headline: headline))
    }

    private func decoration(_ art: TemplateArt, in layout: ScreenshotLayout) -> LayoutDecoration? {
        layout.decorations.first { $0.art == art }
    }

    /// A plain template with one prop over where a centered caption goes.
    private func propOverTheCaption(avoid: TemplateDecoration.Avoidance?) -> ScreenshotTemplate {
        var template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        template.decorations = [TemplateDecoration.art(.star, x: 0.4, y: 0, width: 0.6, height: 0.5, avoid: avoid)]
        return template
    }

    // MARK: - Device

    @Test func theDeviceTopHoldsUnderAShortCaption() throws {
        let result = layout(arcade)
        let device = try #require(result.device)
        #expect(abs(device.frame.minY - 0.267 * result.canvas.height) < 1)
        #expect(device.frame.minY > result.captionBox.maxY)
        #expect(device.frame.maxY > result.canvas.height, "A big phone runs off the bottom")
    }

    @Test func aCaptionThatNeedsTheRoomPushesTheDeviceDown() throws {
        var template = arcade
        template.device.top = 0.1
        let short = layout(template)
        let long = layout(template, headline: Self.longHeadline)
        try #require(long.lines.count >= 3)
        let shortDevice = try #require(short.device)
        let longDevice = try #require(long.device)
        #expect(shortDevice.frame.minY > 0.1 * short.canvas.height, "Under the caption, not at 10%")
        #expect(shortDevice.frame.minY >= short.captionBox.maxY)
        #expect(longDevice.frame.minY >= long.captionBox.maxY)
        #expect(longDevice.frame.minY > shortDevice.frame.minY, "More lines, lower device")
        // Arcade's own top holds even under three lines.
        let pinned = try #require(layout(arcade, headline: Self.longHeadline).device)
        #expect(abs(pinned.frame.minY - 0.267 * long.canvas.height) < 1)
    }

    @Test(arguments: TemplateStarter.allCases)
    func emptyScreensAreBlackInEveryTemplate(starter: TemplateStarter) {
        let template = ScreenshotTemplate.starter(starter, id: "lumen", title: "Lumen")
        #expect(layout(template).emptyScreen == .black, "No stripes or grey placeholder: a switched-off screen")
    }

    // MARK: - Caption box

    @Test func aTightCaptionBoxIsAsTallAsItsLines() throws {
        var loose = arcade
        loose.caption.headline.tight = nil
        let tight = layout(arcade)
        let reserved = layout(loose)
        try #require(tight.lines.count == 1)
        #expect(tight.captionBox.height < reserved.captionBox.height)
        let line = try #require(tight.lines.first)
        #expect(abs(tight.captionBox.height - line.frame.height) < 1)
        // Every language gets the box its lines need, so the device follows.
        let longer = layout(arcade, headline: Self.longHeadline)
        #expect(longer.captionBox.height > tight.captionBox.height)
    }

    // MARK: - Two phones

    @Test func slotThreeStandsAPhoneBehindTheFrontOne() throws {
        let result = layout(arcade, slot: 2)
        let front = try #require(result.device)
        let companion = try #require(result.companion)
        let behind = try #require(companion.device)
        let height = result.canvas.height
        let width = result.canvas.width
        #expect(companion.isBehind)
        #expect(behind.frame.size == front.frame.size)
        #expect(behind.tilt == nil)
        #expect(abs(front.frame.minY - 0.372 * height) < 1)
        #expect(abs(behind.frame.minY - max(0.249 * height, result.captionBox.maxY)) < height * 0.05)
        #expect(behind.frame.minY >= result.captionBox.maxY - 1, "Never over the caption")
        #expect(abs(front.frame.midX - (width / 2 + 0.19 * width)) < 1)
        #expect(abs(behind.frame.midX - (width / 2 - 0.215 * width)) < 1)
        #expect(behind.island != nil)
        #expect(companion.screen.width < behind.frame.width)
    }

    @Test func twoPhonesMirrorRightToLeft() throws {
        let english = layout(arcade, slot: 2)
        let arabic = layout(arcade, slot: 2, locale: .arabic)
        let width = english.canvas.width
        let behind = try #require(english.companion?.device?.frame)
        let mirrored = try #require(arabic.companion?.device?.frame)
        #expect(abs(mirrored.midX - (width - behind.midX)) < 1)
        let front = try #require(english.device?.frame)
        let mirroredFront = try #require(arabic.device?.frame)
        #expect(abs(mirroredFront.midX - (width - front.midX)) < 1)
    }

    @Test func otherSlotsAndLandscapeIPadsHaveOnePhone() {
        #expect(layout(arcade, slot: 1).companion == nil)
        var landscape = arcade
        landscape.canvas.ipad = .landscape
        #expect(layout(landscape, slot: 2, display: .iPad).companion == nil)
    }

    // MARK: - Props

    @Test func anUnderlineAnchoredToTheCaptionSitsUnderItsBox() throws {
        let short = layout(arcade, slot: 1)
        let long = layout(arcade, slot: 1, headline: Self.longHeadline)
        for result in [short, long] {
            let underline = try #require(decoration(.underline, in: result))
            #expect(abs(underline.frame.minY - (result.captionBox.maxY + 0.004 * result.canvas.height)) < 1)
        }
        let first = try #require(decoration(.underline, in: short))
        let second = try #require(decoration(.underline, in: long))
        #expect(second.frame.minY > first.frame.minY, "It follows the box down")
    }

    @Test func anAsteriskFollowsTheFirstLineOnTheReadingSide() throws {
        let english = layout(arcade, slot: 2)
        let line = try #require(english.lines.first)
        let asterisk = try #require(decoration(.asterisk, in: english))
        #expect(asterisk.frame.minX > line.frame.midX)
        #expect(asterisk.frame.maxX <= english.canvas.width)
        #expect(asterisk.frame.midY > line.frame.minY)
        #expect(asterisk.frame.midY < line.frame.maxY)

        let arabic = layout(arcade, slot: 2, locale: .arabic)
        let arabicLine = try #require(arabic.lines.first)
        let mirrored = try #require(decoration(.asterisk, in: arabic))
        #expect(mirrored.frame.maxX < arabicLine.frame.midX, "Right to left, it ends the line on the left")
        #expect(mirrored.isFlipped)
    }

    @Test func anAsteriskWithNoRoomAfterTheLineHides() {
        let result = layout(arcade, slot: 2, headline: "Unbelievable")
        #expect(decoration(.asterisk, in: result) == nil)
        #expect(decoration(.arrow, in: result) != nil)
    }

    @Test func aPropThatDoesntAskMayOverlapTheHeadline() throws {
        let result = layout(propOverTheCaption(avoid: nil))
        let star = try #require(decoration(.star, in: result))
        #expect(abs(star.frame.minX - 0.4 * result.canvas.width) < 1)
        #expect(abs(star.frame.width - 0.6 * result.canvas.width) < 1)
        #expect(star.frame.minY == 0)
    }

    @Test func aPropThatMovesDownClearsTheCaption() throws {
        let result = layout(propOverTheCaption(avoid: .down))
        let star = try #require(decoration(.star, in: result))
        #expect(star.frame.minY >= result.captionBox.maxY)
        #expect(abs(star.frame.width - 0.6 * result.canvas.width) < 1, "Same size, lower")
    }

    @Test func aPropThatSqueezesNarrowsAwayFromTheLetters() throws {
        let english = layout(propOverTheCaption(avoid: .squeeze))
        let width = english.canvas.width
        let star = try #require(decoration(.star, in: english))
        #expect(star.frame.minX > width / 2, "Starts after the centered word")
        #expect(abs(star.frame.maxX - width) < 1, "Keeps its far edge")
        #expect(star.frame.minY == 0)

        let arabic = layout(propOverTheCaption(avoid: .squeeze), locale: .arabic)
        let mirrored = try #require(decoration(.star, in: arabic))
        #expect(abs(mirrored.frame.minX) < 1, "Mirrored: keeps the left edge")
        #expect(mirrored.frame.maxX < width / 2)
    }

    @Test func aPropThatHidesIsLeftOutWhereItMeetsTheLetters() {
        #expect(decoration(.star, in: layout(propOverTheCaption(avoid: .hide))) == nil)
        // Under a caption that doesn't reach it, it stays.
        var template = propOverTheCaption(avoid: .hide)
        template.decorations?[0].y = 0.8
        template.decorations?[0].height = 0.1
        #expect(decoration(.star, in: layout(template)) != nil)
    }

    @Test func aHiddenPropIsntLaidOut() {
        var template = arcade
        template.slots[0].over["deco"] = nil
        template.decorations = [TemplateDecoration.art(.controller, x: 0.73, y: 0.19, width: 0.34, height: 0.11)]
        #expect(decoration(.controller, in: layout(template)) != nil)
        template.decorations?[0].hidden = true
        #expect(decoration(.controller, in: layout(template)) == nil)
    }

    @Test func propsFlipRightToLeft() throws {
        let english = try #require(decoration(.chess, in: layout(arcade, slot: 1)))
        let arabicLayout = layout(arcade, slot: 1, locale: .arabic)
        let arabic = try #require(decoration(.chess, in: arabicLayout))
        #expect(!english.isFlipped)
        #expect(arabic.isFlipped)
        #expect(abs(arabic.frame.midX - (arabicLayout.canvas.width - english.frame.midX)) < 1)
    }

    @Test func theFigureLinesUpAcrossTheSeamInBothDirections() throws {
        let width = layout(arcade).canvas.width
        let fourth = try #require(decoration(.person, in: layout(arcade, slot: 3)))
        let fifth = try #require(decoration(.person, in: layout(arcade, slot: 4)))
        // Left to right, slot 5 sits to the right of slot 4.
        #expect(abs((fourth.frame.minX - width) - fifth.frame.minX) < 1)
        let arabicFourth = try #require(decoration(.person, in: layout(arcade, slot: 3, locale: .arabic)))
        let arabicFifth = try #require(decoration(.person, in: layout(arcade, slot: 4, locale: .arabic)))
        // Right to left, slot 5 sits to the left of slot 4.
        #expect(abs(arabicFourth.frame.minX - (arabicFifth.frame.minX - width)) < 1)
        #expect(arabicFourth.isFlipped)
    }

    // MARK: - Fonts

    @Test func scriptsBoldonseCantDrawFallBackHeavier() throws {
        let english = layout(arcade)
        #expect(english.lines.first?.weight == 400)
        let japanese = layout(arcade, locale: .japanese, headline: "毎日を記録")
        let line = try #require(japanese.lines.first)
        #expect(line.fontName != "Boldonse")
        #expect(line.weight == 800)
        let russian = layout(arcade, locale: .russian, headline: "Играй")
        #expect(russian.lines.first?.weight == 800)
    }
}
