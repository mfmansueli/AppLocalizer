//
//  LandscapeOverridesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `lan`: a template's values for landscape canvases only (iPad lying
/// down, Mac), saved under the design's key; Cinema, Highlight and Arcade
/// use them.
@Suite("Landscape overrides (lan)")
struct LandscapeOverridesTests {
    @Test func theyAreSavedAsLan() throws {
        let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
        let json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(arcade)) as? [String: Any])
        #expect(json["lan"] != nil)
        #expect(json["landscape"] == nil)
    }

    @Test func templatesSavedWithTheOldKeyStillRead() throws {
        let arcade = ScreenshotTemplate.starter(.arcade, id: "lumen", title: "Lumen")
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(arcade)) as? [String: Any])
        json["landscape"] = json.removeValue(forKey: "lan")
        let decoded = try JSONDecoder().decode(ScreenshotTemplate.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.landscape == arcade.landscape)
    }

    @Test func cinemaGetsASmallerPhoneWithAGentlerTilt() {
        let cinema = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        let lying = cinema.resolved(forSlot: 1, isLandscape: true)
        #expect(lying.device.width == 0.5)
        #expect(lying.device.tilt == TemplateTilt(rotate: -5, turn: 12, lean: 8))
        #expect(lying.device.shiftDown == 0)
        #expect(lying.device.offset == 0)
        let standing = cinema.resolved(forSlot: 1)
        #expect(standing.device.width == 0.64, "Portrait keeps the slot's own width")
    }

    @Test func highlightGetsMoreRoomUnderTheCaption() {
        let highlight = ScreenshotTemplate.starter(.highlight, id: "lumen", title: "Lumen")
        let lying = highlight.resolved(forSlot: 0, isLandscape: true)
        #expect(lying.caption.gap == 0.07)
        #expect(lying.device.shiftRight == 0.1)
        #expect(lying.device.tilt == TemplateTilt(rotate: 8, turn: -8, lean: 10))
        #expect(highlight.resolved(forSlot: 0).caption.gap == 0.028)
    }

    @Test func aLanPathCantOverrideLan() {
        var template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        template.landscape = ["lan": .object([:]), "device.dx": .double(0.1)]
        let resolved = template.resolved(forSlot: 0, isLandscape: true)
        #expect(resolved.device.shiftRight == 0.1)
        #expect(resolved.landscape == template.landscape)
    }
}
