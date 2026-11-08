//
//  ArcadeTemplateFieldsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The fields Arcade added, in JSON and through the applier the editor and
/// `propose_template` share: `device.top`, `device.empty`, `device.pair`,
/// `caption.headline.tight`, the `pair` slot layout, and props with their
/// `anchor`, `avoid`, `span` and `off`.
@MainActor
@Suite("Arcade template fields")
struct ArcadeTemplateFieldsTests {
    private let applier = TemplateOperationApplier()
    private let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    private func refusals(_ operations: [TemplateOperation]) -> [TemplateRefusal] {
        switch applier.applying(operations, to: template) {
        case .success: []
        case let .failure(refusals): refusals.items
        }
    }

    private func applied(_ operations: [TemplateOperation]) throws -> ScreenshotTemplate {
        try applier.applying(operations, to: template).get()
    }

    // MARK: - JSON

    @Test func aPropReadsItsKeysAndDefaultsToWhite() throws {
        let prop = try decode(
            TemplateDecoration.self,
            #"{"type": "art", "art": "dice", "x": 0.78, "y": 0.2, "w": 0.27, "h": 0.12, "rot": 14, "avoid": "down", "span": 4, "off": true}"#
        )
        #expect(prop.type == .art)
        #expect(prop.art == .dice)
        #expect(prop.color == "#FFFFFF")
        #expect(prop.layer == .front)
        #expect(prop.avoid == .down)
        #expect(prop.span == 4)
        #expect(prop.isHidden)
        #expect(prop.title == "Die")
        let anchored = try decode(TemplateDecoration.self, #"{"type": "art", "art": "asterisk", "x": 0, "y": 0, "w": 0.13, "anchor": "l1end"}"#)
        #expect(anchored.anchor == .firstLineEnd)
        #expect(!anchored.isHidden)
        let under = try decode(TemplateDecoration.self, #"{"type": "art", "art": "underline", "x": 0, "y": 0, "w": 0.7, "anchor": "cap"}"#)
        #expect(under.anchor == .caption)
    }

    @Test func aShapeStillNeedsItsColor() {
        #expect(throws: DecodingError.self) {
            try decode(TemplateDecoration.self, #"{"type": "shape", "shape": "blob", "x": 0, "y": 0, "w": 0.2}"#)
        }
    }

    @Test func aPropSurvivesJSON() throws {
        var prop = TemplateDecoration.art(.corner, x: 0.865, y: -0.005, width: 0.14, height: 0.27, layer: .back, avoid: .squeeze, span: 2)
        prop.hidden = true
        let decoded = try JSONDecoder().decode(TemplateDecoration.self, from: JSONEncoder().encode(prop))
        #expect(decoded == prop)
    }

    @Test func theDeviceReadsTopEmptyAndPair() throws {
        let device = try decode(
            TemplateDevice.self,
            ##"{"show": true, "width": 0.85, "color": "#A9ACB4", "offset": 0, "bleed": 0.3, "top": 0.267, "empty": "black", "pair": {"dx": -0.2}}"##
        )
        #expect(device.top == 0.267)
        #expect(device.emptyScreen == .black)
        #expect(device.pair == TemplateDevicePair(shiftRight: -0.2, top: nil))
        let plain = try decode(TemplateDevice.self, ##"{"show": true, "width": 0.8, "color": "#000000", "offset": 0, "bleed": 0}"##)
        #expect(plain.top == nil)
        #expect(plain.emptyScreen == nil)
        #expect(plain.emptyScreenColor == .black, "Black whether or not the template says so")
        #expect(plain.pair == nil)
        #expect(try decode(TemplateDevicePair.self, #"{"top": 0.3}"#) == TemplateDevicePair(shiftRight: 0, top: 0.3))
    }

    @Test func theArcadeStarterSurvivesJSONWithItsNewFields() throws {
        let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
        let data = try JSONEncoder().encode(arcade)
        let text = try #require(String(bytes: data, encoding: .utf8))
        #expect(text.contains(#""tight":true"#))
        #expect(text.contains(#""empty":"black""#))
        #expect(text.contains(#""layout":"pair""#))
        #expect(try JSONDecoder().decode(ScreenshotTemplate.self, from: data) == arcade)
    }

    // MARK: - Applier

    @Test func theNewDeviceFieldsApply() throws {
        let updated = try applied([
            .replace("device.top", with: .double(0.3)),
            .replace("device.empty", with: "black"),
            .replace("device.bleed", with: .double(0.3)),
            .replace("device.pair", with: .object(["dx": .double(-0.3), "top": .double(0.2)])),
            .replace("caption.headline.tight", with: .bool(true)),
            .replace("slots.2.layout", with: "pair"),
        ])
        #expect(updated.device.top == 0.3)
        #expect(updated.device.emptyScreen == .black)
        #expect(updated.device.bleed == 0.3)
        #expect(updated.device.pair == TemplateDevicePair(shiftRight: -0.3, top: 0.2))
        #expect(updated.caption.headline.isTight)
        #expect(updated.slots[2].layout == .pair)
    }

    @Test func outOfRangeDeviceFieldsAreRefused() {
        #expect(refusals([.replace("device.top", with: .double(0.7))]).map(\.kind) == [.outOfRange])
        #expect(refusals([.replace("device.bleed", with: .double(0.4))]).map(\.kind) == [.outOfRange])
        #expect(refusals([.replace("device.empty", with: "white")]).map(\.kind) == [.outOfRange])
        #expect(refusals([.replace("device.pair", with: .object(["dx": .double(0.9)]))]).map(\.kind) == [.outOfRange])
        #expect(refusals([.replace("device.pair", with: "left")]).map(\.kind) == [.wrongType])
        #expect(refusals([.replace("slots.2.layout", with: "trio")]).map(\.kind) == [.outOfRange])
    }

    @Test func aPropNamesItsArtAndSpansARealSlot() throws {
        let unnamed: JSONValue = .array([.object(["type": "art", "x": .double(0), "y": .double(0), "w": .double(0.2)])])
        let missing = refusals([.replace("slots.1.over.deco", with: unnamed)])
        #expect(missing.map(\.kind) == [.wrongType])
        #expect(missing.first?.path.hasSuffix(".art") == true)
        #expect(missing.first?.reason.contains("controller") == true)

        let farSlot: JSONValue = .array([.object(["type": "art", "art": "person", "x": .double(0), "y": .double(0), "w": .double(0.2), "span": .int(12)])])
        #expect(!refusals([.replace("slots.1.over.deco", with: farSlot)]).isEmpty)

        let good: JSONValue = .array([.object([
            "type": "art", "art": "asterisk", "x": .double(0), "y": .double(0), "w": .double(0.13), "anchor": "l1end", "avoid": "hide",
        ])])
        let updated = try applied([.replace("slots.1.over.deco", with: good)])
        #expect(updated.resolved(forSlot: 1).decorations?.first?.anchor == .firstLineEnd)
    }
}
