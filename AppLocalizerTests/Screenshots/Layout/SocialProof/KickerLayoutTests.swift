//
//  KickerLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The kicker line (`caption.kicker`): a short topic line over the
/// headline, per slot and language. With one, the headline sits right under
/// it and the box is as tall as the real lines; without kicker text, the
/// slot shows the headline alone.
@MainActor
@Suite("Kicker line")
struct KickerLayoutTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)
    private let proof = ScreenshotTemplate.starter(.socialProof, id: "lumen", title: "Lumen")

    private func layout(_ caption: ScreenshotCaption, slot: Int = 2, template: ScreenshotTemplate? = nil) -> ScreenshotLayout {
        engine.layout(template ?? proof, slot: slot, locale: .englishUS, displayType: .iPhone, caption: caption)
    }

    @Test func theKickerSitsOverTheHeadline() throws {
        let result = layout(ScreenshotCaption(headline: "Search every entry", kicker: "Find anything"))
        let kicker = try #require(result.lines.first { $0.text == "Find anything" })
        let headline = try #require(result.lines.first { $0.text.hasPrefix("Search") })
        #expect(kicker.frame.maxY <= headline.frame.minY + 0.5, "The headline starts under the kicker")
        #expect(kicker.frame.minY >= result.captionBox.minY - 0.5)
        #expect(kicker.weight == 400)
        #expect(kicker.pixelSize < headline.pixelSize)
        #expect(result.headline.lines.joined(separator: " ") == "Search every entry", "The headline is the layout's headline")
        #expect(result.lines.first?.text.hasPrefix("Search") == true, "Its lines come first, for the decorations")
    }

    @Test func withoutKickerTextTheHeadlineIsAlone() throws {
        let with = layout(ScreenshotCaption(headline: "Search every entry", kicker: "Find anything"))
        let without = layout(ScreenshotCaption(headline: "Search every entry"))
        let headline = try #require(without.lines.first)
        #expect(without.lines.allSatisfy { $0.text != "Find anything" })
        #expect(abs(headline.frame.minY - without.captionBox.minY) < 1, "The headline takes the kicker's place")
        #expect(without.captionBox.height < with.captionBox.height)
        let deviceWith = try #require(with.device)
        let deviceWithout = try #require(without.device)
        #expect(deviceWithout.frame.minY < deviceWith.frame.minY, "The device follows the text's real height")
    }

    @Test func aKickerMakesTheBoxTight() {
        // Social Proof reserves three headline lines; one line is all it takes.
        let short = layout(ScreenshotCaption(headline: "Write", kicker: "Daily"))
        let style = proof.caption.headline
        let reserved = CGFloat(Double(style.maxLines) * style.size * style.lineHeight) * short.canvas.unit
        #expect(short.captionBox.height < reserved)
    }

    @Test func aTemplateWithoutAKickerIgnoresTheText() {
        let above = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        let result = layout(ScreenshotCaption(headline: "Write every day", kicker: "Daily"), slot: 1, template: above)
        #expect(result.lines.allSatisfy { $0.text != "Daily" })
    }

    @Test func theKickerIsPartOfTheRenderText() {
        let plain = ScreenshotCaption(headline: "Write")
        #expect(ScreenshotCaption(headline: "Write", kicker: "  ").renderText == plain.renderText, "An empty kicker keeps the old key")
        #expect(ScreenshotCaption(headline: "Write", kicker: "Daily").renderText != plain.renderText)
    }

    @Test func theKickerSurvivesJSON() throws {
        let caption = ScreenshotCaption(headline: "Write", kicker: "Daily")
        let decoded = try JSONDecoder().decode(ScreenshotCaption.self, from: JSONEncoder().encode(caption))
        #expect(decoded.kicker == "Daily")
        let plain = try JSONEncoder().encode(ScreenshotCaption(headline: "Write"))
        let json = try #require(String(bytes: plain, encoding: .utf8))
        #expect(!json.contains("kicker"), "Nothing new is written without one")
        #expect(try JSONDecoder().decode(ScreenshotCaption.self, from: plain).kicker == nil, "Captions saved before kickers still read")
    }

    @Test func aProposalCanSetAndRemoveTheKickerStyle() throws {
        let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        let style = JSONValue.object([
            "font": .string("Poppins"), "weight": .int(400), "size": .double(86), "min": .double(62), "lh": .double(1.15), "maxLines": .int(1),
        ])
        let applier = TemplateOperationApplier(fonts: ScreenshotsTestFixtures.fonts)
        let added = try applier.applying([TemplateOperation(path: "caption.kicker", value: style)], to: template).get()
        #expect(added.caption.kicker?.size == 86)
        let removed = try applier.applying([TemplateOperation(path: "caption.kicker", value: .null)], to: added).get()
        #expect(removed.caption.kicker == nil)
        let refused = applier.applying([TemplateOperation(path: "caption.kicker", value: .string("big"))], to: added)
        #expect((try? refused.get()) == nil)
    }
}
