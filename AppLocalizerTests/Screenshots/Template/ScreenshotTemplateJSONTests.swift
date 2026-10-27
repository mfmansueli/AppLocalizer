//
//  ScreenshotTemplateJSONTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The template JSON is the contract with the renderer and the MCP tools:
/// the README's §3 example decodes, re-encodes to the same JSON, and slot
/// overrides resolve over the template's values.
@MainActor
@Suite("ScreenshotTemplate JSON")
struct ScreenshotTemplateJSONTests {
    static let readmeExample = """
    {
      "schema": "applocalizer.screenshot-template/1",
      "id": "lumen", "name": "Lumen · Caption above device", "version": 4,
      "starter": "above",
      "canvas": { "iphone": "portrait", "ipad": "landscape" },
      "bg": { "kind": "linear", "angle": 168, "stops": ["#7A80FF", "#3A2FB8"] },
      "device": { "show": true, "width": 0.80, "color": "#141416", "offset": 0, "bleed": 0.07 },
      "caption": {
        "placement": "above", "align": "center", "gap": 0.028,
        "ink": "#FFFFFF", "subInk": "rgba(255,255,255,0.84)",
        "band": { "color": "#17143D", "pos": "bottom" },
        "headline": { "font": "SF Pro Display", "weight": 700, "size": 112, "min": 80,
                      "lh": 1.08, "maxLines": 2, "tracking": -0.01 },
        "subhead":  { "font": "SF Pro Text", "weight": 500, "size": 50, "min": 42,
                      "lh": 1.24, "maxLines": 2 }
      },
      "fit": { "shrink": true, "hyphenate": false },
      "rtl": { "mirror": true },
      "safe": { "top": 0.06, "side": 0.075, "bottom": 0 },
      "fonts": { "display": "SF Pro Display",
                 "fallback": { "arabic": "SF Arabic", "hebrew": "SF Hebrew", "ja": "Hiragino Sans",
                               "zh-Hans": "PingFang SC", "zh-Hant": "PingFang TC", "ko": "Apple SD Gothic Neo",
                               "thai": "Thonburi", "devanagari": "Kohinoor Devanagari",
                               "cyrillic": "SF Pro Display", "greek": "SF Pro Display", "vietnamese": "SF Pro Display" } },
      "slots": [
        { "layout": "hero", "over": {} },
        { "layout": "standard", "over": { "caption.headline.size": 104 } },
        { "layout": "standard", "over": {} }, { "layout": "standard", "over": {} }, { "layout": "standard", "over": {} }
      ]
    }
    """

    static func decode(_ text: String = readmeExample) throws -> ScreenshotTemplate {
        try JSONDecoder().decode(ScreenshotTemplate.self, from: Data(text.utf8))
    }

    @Test func theReadmeExampleDecodes() throws {
        let template = try Self.decode()
        #expect(template.version == 4)
        #expect(template.starter == .above)
        #expect(template.background.kind == .linear)
        #expect(template.background.stops == ["#7A80FF", "#3A2FB8"])
        #expect(template.caption.headline.size == 112)
        #expect(template.caption.headline.lineHeight == 1.08)
        #expect(template.caption.subhead.tracking == nil)
        #expect(template.fonts.fallback[.japanese] == "Hiragino Sans")
        #expect(template.fonts.fallback[.thai] == "Thonburi")
        #expect(template.slots.map(\.layout) == [.hero, .standard, .standard, .standard, .standard])
        #expect(template.slots[1].over["caption.headline.size"] == 104)
    }

    @Test func reEncodingGivesTheSameJSON() throws {
        let template = try Self.decode()
        let original = try JSONDecoder().decode(JSONValue.self, from: Data(Self.readmeExample.utf8))
        let encoded = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(template))
        #expect(encoded == original)
        #expect(try ScreenshotTemplate(json: template.json) == template)
    }

    @Test func lineHeightIsWrittenAsLH() throws {
        let data = try JSONEncoder().encode(Self.decode())
        let text = try #require(String(bytes: data, encoding: .utf8))
        #expect(text.contains(#""lh":1.08"#))
        #expect(!text.contains("lineHeight"))
    }

    @Test func aSlotOverrideWinsOverTheTemplateValue() throws {
        let template = try Self.decode()
        #expect(template.value(at: "caption.headline.size") == 112)
        #expect(template.value(at: "caption.headline.size", slot: 1) == 104)
        #expect(template.value(at: "caption.headline.size", slot: 2) == 112)
        #expect(template.resolved(forSlot: 1).caption.headline.size == 104)
        #expect(template.resolved(forSlot: 0).caption.headline.size == 112)
    }

    @Test func removingAnOverrideReturnsToTheTemplateValue() throws {
        var template = try Self.decode()
        template.slots[1].over = [:]
        #expect(template.resolved(forSlot: 1).caption.headline.size == 112)
    }

    @Test func slotOneIsTheHero() throws {
        let template = try Self.decode()
        #expect(template.isHero(slot: 0))
        #expect(!template.isHero(slot: 1))
    }

    @Test func aNullFallbackDecodesAsNoFallback() throws {
        let text = Self.readmeExample.replacingOccurrences(of: #""thai": "Thonburi""#, with: #""thai": null"#)
        let template = try Self.decode(text)
        #expect(template.fonts.fallback[.thai] == nil)
    }
}
