//
//  ArcadeStarterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Arcade as the design draws it: Boldonse caps on electric blue, big
/// phones pinned at 27% with black empty screens, Two phones on slot 3,
/// props on every slot and one figure across the seam between slots 4
/// and 5.
@MainActor
@Suite("Arcade starter")
struct ArcadeStarterTests {
    private let template = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")

    private func arts(_ template: ScreenshotTemplate, slot: Int) -> [TemplateArt] {
        template.resolved(forSlot: slot).decorations?.compactMap(\.art) ?? []
    }

    @Test func itIsABoldTemplateInBoldonseCapsOnBlue() {
        #expect(TemplateStarter.arcade.style == .bold)
        #expect(TemplateStarter.arcade.tags == ["Condensed caps", "Two phones", "Props across slots"])
        #expect(template.name == "Lumen · Arcade")
        let headline = template.caption.headline
        #expect(headline.font == "Boldonse")
        #expect(headline.weight == 400)
        #expect(headline.size == 143)
        #expect(headline.min == 84)
        #expect(headline.maxLines == 3)
        #expect(headline.uppercase == true)
        #expect(headline.isTight)
        #expect(template.caption.subhead.font == "SF Pro Text")
        #expect(template.background.kind == .linear)
        #expect(template.background.angle == 165)
        #expect(template.background.stops == ["#4B70FF", "#3F63FB", "#3A5CF2"])
    }

    @Test func thePhonesArePinnedAndRunOffTheBottomWithBlackEmptyScreens() {
        #expect(template.device.width == 0.85)
        #expect(template.device.color == "#A9ACB4")
        #expect(template.device.top == 0.267)
        #expect(template.device.bleed == 0.3)
        #expect(template.device.emptyScreen == .black)
        #expect(template.device.emptyScreenColor == .black)
        #expect(template.device.tilt?.isFlat ?? true)
    }

    @Test func slotThreeStacksTwoPhones() {
        #expect(template.slots.map(\.layout) == [.standard, .standard, .pair, .standard, .standard])
        let third = template.resolved(forSlot: 2).device
        #expect(third.pair == TemplateDevicePair(shiftRight: -0.215, top: 0.249))
        #expect(third.top == 0.372)
        #expect(third.shiftRight == 0.19)
        #expect(TemplateDevicePair(shiftRight: -0.22, top: 0.25).summary == "22% left, top at 25%")
        #expect(TemplateDevicePair(shiftRight: 0.3, top: nil).summary == "30% right")
    }

    @Test func thePhoneBehindShowsTheSlotBefore() {
        #expect(template.behindSlot(2, templateSlot: 2, count: 5) == 1)
        #expect(template.behindSlot(0, templateSlot: 2, count: 5) == 4, "The first wraps to the last")
        #expect(template.behindSlot(3, templateSlot: 3, count: 5) == nil, "Slot 4 has one phone")
        #expect(template.behindSlot(0, templateSlot: 2, count: 1) == nil, "A set of one has nothing to put behind")
    }

    @Test func everySlotHasItsProps() {
        #expect(arts(template, slot: 0) == [.controller])
        #expect(arts(template, slot: 1) == [.underline, .chess])
        #expect(arts(template, slot: 2) == [.asterisk, .arrow])
        #expect(arts(template, slot: 3) == [.corner, .pointer, .person])
        #expect(arts(template, slot: 4) == [.star, .dice, .person])
    }

    @Test func propsFollowOrStepAsideFromTheHeadline() {
        let second = template.resolved(forSlot: 1).decorations ?? []
        #expect(second.first { $0.art == .underline }?.anchor == .caption)
        let third = template.resolved(forSlot: 2).decorations ?? []
        #expect(third.first { $0.art == .asterisk }?.anchor == .firstLineEnd)
        #expect(third.first { $0.art == .arrow }?.avoid == .down)
        let fourth = template.resolved(forSlot: 3).decorations ?? []
        #expect(fourth.first { $0.art == .corner }?.avoid == .squeeze)
        #expect(fourth.first { $0.art == .corner }?.layer == .back)
        let fifth = template.resolved(forSlot: 4).decorations ?? []
        #expect(fifth.first { $0.art == .star }?.avoid == .hide)
        #expect(fifth.first { $0.art == .dice }?.rotation == 14)
    }

    @Test func oneFigureSpansSlotsFourAndFive() throws {
        let fourth = try #require(template.resolved(forSlot: 3).decorations?.first { $0.art == .person })
        let fifth = try #require(template.resolved(forSlot: 4).decorations?.first { $0.art == .person })
        #expect(fourth.span == 4)
        #expect(fifth.span == 3)
        // The halves line up across the seam: slot 5 starts where slot 4 ends.
        #expect(abs((fourth.x - 1) - fifth.x) < 0.000_1)
        #expect(fourth.width == fifth.width)
        #expect(fourth.y == fifth.y)
    }

    @Test func multiColorPropsKeepTheirColors() throws {
        let controller = try #require(template.resolved(forSlot: 0).decorations?.first)
        #expect(!controller.takesColor)
        #expect(!TemplateArt.controller.isTintable)
        let underline = try #require(template.resolved(forSlot: 1).decorations?.first)
        #expect(underline.takesColor)
        #expect(TemplateArt.person.title == "Figure")
        #expect(controller.title == "Game controller")
    }

    @Test func slotsPastTheFifthKeepTwoPhonesButNotTheFigure() {
        let long = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen", slotCount: 9)
        #expect(long.slots.count == 9)
        // Slot 7 repeats slot 3, Two phones and all.
        #expect(long.slots[6].layout == .pair)
        #expect(long.resolved(forSlot: 6).device.pair == template.resolved(forSlot: 2).device.pair)
        // Slots 8 and 9 repeat 4 and 5 without the figure: its other half isn't beside it.
        #expect(arts(long, slot: 7) == [.corner, .pointer])
        #expect(arts(long, slot: 8) == [.star, .dice])
        #expect(long.slots[5].layout == .standard)
    }
}
