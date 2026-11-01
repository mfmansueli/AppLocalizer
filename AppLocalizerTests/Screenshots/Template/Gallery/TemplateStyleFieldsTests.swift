//
//  TemplateStyleFieldsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The gallery's template fields in JSON: the short keys the design uses
/// (`rz`, `on`, `mark`, `deco`, `w`, `z`…), lenient angles, CSS-like
/// shadows and rating values.
@Suite("Template style fields")
struct TemplateStyleFieldsTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func anAngleLeftOutIsZero() throws {
        let tilt = try decode(TemplateTilt.self, #"{"rz": 6}"#)
        #expect(tilt == TemplateTilt(rotate: 6, turn: 0, lean: 0))
        #expect(!tilt.isFlat)
        #expect(TemplateTilt.flat.isFlat)
        #expect(TemplateTilt(rotate: 5, turn: -16, lean: 0).summary == "rotate 5°, turn -16°")
    }

    @Test func aTiltEncodesWithTheShortKeys() throws {
        let data = try JSONEncoder().encode(TemplateTilt(rotate: 1, turn: 2, lean: 3))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Double])
        #expect(object == ["rz": 1, "ry": 2, "rx": 3])
    }

    @Test func shadowsReadEmLengthsAndAColor() throws {
        let shadow = try #require(TemplateShadow("0 0.05em 0 rgba(18,10,70,0.5)"))
        #expect(shadow.x == 0)
        #expect(shadow.y == 0.05)
        #expect(shadow.blur == 0)
        let hex = try #require(TemplateShadow("0.07em 0.07em 0 #4B10A8"))
        #expect(hex.x == 0.07)
        #expect(TemplateShadow("2px 2px red") == nil, "Pixels and color names aren't shadows")
        #expect(TemplateShadow("0.1em") == nil)
    }

    @Test func emphasisAppliesToTheFirstOfSeveralLinesOrTheLast() {
        let first = TemplateEmphasis(line: .first, weight: 400)
        #expect(first.applies(toLine: 0, of: 2))
        #expect(!first.applies(toLine: 0, of: 1), "A one-line headline keeps its weight")
        let last = TemplateEmphasis(line: .last, weight: 800)
        #expect(last.applies(toLine: 2, of: 3))
        #expect(!last.applies(toLine: 1, of: 3))
    }

    @Test func aDecorationReadsTheDesignsKeys() throws {
        let decoration = try decode(
            TemplateDecoration.self,
            ##"{"type": "shape", "shape": "swoosh", "x": 0.1, "y": 0.2, "w": 0.5, "color": "#FFFFFF", "z": "back", "rot": 12, "op": 0.8}"##
        )
        #expect(decoration.shape == .swoosh)
        #expect(decoration.width == 0.5)
        #expect(decoration.layer == .back)
        #expect(decoration.rotation == 12)
        #expect(decoration.opacity == 0.8)
        #expect(decoration.title == "Ribbon")
        #expect(!decoration.isRating)
    }

    @Test func ratingValuesReadTheirNumber() {
        let laurel = TemplateDecoration.laurel(x: 0.3, y: 0.78, width: 0.4, color: "#FFFFFF", value: "4.8")
        #expect(laurel.isRating)
        #expect(laurel.stars == true)
        #expect(laurel.ratingValue == 4.8)
        #expect(laurel.title == "Rating laurel")
        let badge = TemplateDecoration.badge(x: 0, y: 0, width: 0.3, color: "#111111", ink: "#FFFFFF", value: "4,5 ★")
        #expect(badge.ratingValue == 4.5)
        #expect(TemplateDecoration.shape(.sparkle, x: 0, y: 0, width: 0.1, color: "#FFFFFF", layer: .front).ratingValue == nil)
    }

    @Test func aTemplatesDecorationsAndStylesSurviveJSON() throws {
        var template = ScreenshotTemplate.starter(.highlight, id: "lumen", title: "Lumen")
        template.caption.headline.uppercase = true
        let data = try JSONEncoder().encode(template)
        let text = try #require(String(data: data, encoding: .utf8))
        #expect(text.contains("\"mark\""))
        #expect(text.contains("\"upper\""))
        #expect(try JSONDecoder().decode(ScreenshotTemplate.self, from: data) == template)
    }
}
