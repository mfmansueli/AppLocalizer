//
//  SocialProofStarterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Social Proof, the 14th template, as the design canvas defines it: a
/// Poppins kicker over a heavy headline on ink, lilac and mist, a rating
/// laurel on slot 1, real reviews on slot 2, a moon and sparkles on slot 3
/// and a hand holding the phone on slot 5.
@Suite("Social Proof starter")
struct SocialProofStarterTests {
    private let template = ScreenshotTemplate.starter(.socialProof, id: "lumen", title: "Lumen")

    @Test func itsABoldNewTemplateBeforeArcade() {
        let starter = TemplateStarter.socialProof
        #expect(starter.rawValue == "proof", "The design's key")
        #expect(starter.style == .bold)
        #expect(starter.isNew)
        #expect(starter.title == "Social Proof")
        #expect(starter.tags == ["Kicker line", "Reviews slot", "Hand and illustration"])
        let all = TemplateStarter.allCases
        #expect(all.firstIndex(of: .socialProof) == all.firstIndex(of: .arcade).map { $0 - 1 }, "Board order: Highlight, Social Proof, Arcade")
    }

    @Test func theCaptionHasAKickerOverAHeavyHeadline() throws {
        let kicker = try #require(template.caption.kicker)
        #expect(kicker.font == "Poppins")
        #expect(kicker.weight == 400)
        #expect(kicker.size == 86)
        #expect(kicker.maxLines == 1)
        #expect(template.caption.headline.font == "Poppins")
        #expect(template.caption.headline.weight == 700)
        #expect(template.caption.align == .start)
    }

    @Test func slotsAlternateInkLilacAndMist() {
        #expect(template.resolved(forSlot: 0).background.stops == ["#2A2340"])
        #expect(template.resolved(forSlot: 1).background.stops == ["#B6A4CB"])
        #expect(template.resolved(forSlot: 2).background.stops == ["#E9E7EC"])
        #expect(template.resolved(forSlot: 3).background.stops == ["#B6A4CB"])
        #expect(template.resolved(forSlot: 0).caption.ink == "#FFFFFF")
    }

    @Test func theDecorationsAreTheDesigns() throws {
        let laurel = try #require(template.resolved(forSlot: 0).decorations?.first)
        #expect(laurel.type == .laurel)
        #expect(laurel.showsStoreRating)
        #expect(template.slots[1].layout == .quotes)
        #expect(template.resolved(forSlot: 2).decorations?.compactMap(\.shape) == [.moon, .sparkle, .sparkle])
        let hand = try #require(template.resolved(forSlot: 4).decorations)
        #expect(hand.compactMap(\.shape) == [.palm, .fingers])
        #expect(hand.map(\.layer) == [.back, .front], "The palm behind the phone, the fingers over it")
    }

    @Test func theStarterNameSurvivesJSON() throws {
        let decoded = try JSONDecoder().decode(ScreenshotTemplate.self, from: JSONEncoder().encode(template))
        #expect(decoded.starter == .socialProof)
        #expect(decoded.slots[1].layout == .quotes)
        #expect(decoded.caption.kicker == template.caption.kicker)
    }
}
