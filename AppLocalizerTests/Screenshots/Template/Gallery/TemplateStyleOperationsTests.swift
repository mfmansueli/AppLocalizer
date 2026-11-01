//
//  TemplateStyleOperationsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What the applier accepts and refuses for the gallery's fields, from the
/// inspector or an assistant's proposal.
@MainActor
@Suite("Template style operations")
struct TemplateStyleOperationsTests {
    private let applier = TemplateOperationApplier()
    private let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")

    private func refusals(_ operations: [TemplateOperation]) -> [TemplateRefusal] {
        switch applier.applying(operations, to: template) {
        case .success: []
        case let .failure(refusals): refusals.items
        }
    }

    private func applied(_ operations: [TemplateOperation]) throws -> ScreenshotTemplate {
        try applier.applying(operations, to: template).get()
    }

    @Test func aSlotsAngleApplies() throws {
        let updated = try applied([.replace("slots.1.over.device.tilt", with: ["rz": 6, "ry": -10, "rx": 4])])
        #expect(updated.resolved(forSlot: 1).device.tilt == TemplateTilt(rotate: 6, turn: -10, lean: 4))
        #expect(updated.resolved(forSlot: 0).device.tilt == nil)
    }

    @Test func anAngleTooSteepIsRefused() {
        let items = refusals([.replace("device.tilt", with: ["rz": 50])])
        #expect(items.map(\.kind) == [.outOfRange])
        #expect(items.first?.path == "device.tilt.rz")
    }

    @Test func belowIsAPlacement() throws {
        #expect(try applied([.replace("caption.placement", with: "below")]).caption.placement == .below)
    }

    @Test func theHeadlinesLookApplies() throws {
        let updated = try applied([
            .replace("caption.headline.upper", with: true),
            .replace("caption.headline.emph", with: ["on": "first", "weight": 400]),
            .replace("caption.headline.mark", with: ["color": "#CFAEFF", "pad": .double(0.2), "rot": -2]),
            .replace("caption.headline.shadow", with: "0 0.05em 0 rgba(0,0,0,0.4)"),
        ])
        let headline = updated.caption.headline
        #expect(headline.isUppercase)
        #expect(headline.emphasis == TemplateEmphasis(line: .first, weight: 400))
        #expect(headline.highlight?.color == "#CFAEFF")
        #expect(headline.shadow != nil)
    }

    @Test func aBrokenShadowOrHighlightIsRefused() {
        #expect(refusals([.replace("caption.headline.shadow", with: "big")]).count == 1)
        #expect(refusals([.replace("caption.headline.mark", with: ["color": "lavender"])]).first?.path == "caption.headline.mark.color")
        #expect(refusals([.replace("caption.headline.emph", with: ["on": "middle"])]).first?.kind == .wrongType)
    }

    @Test func aRatingShowsNumbersOnly() {
        let laurel = ScreenshotTemplate.encoded(TemplateDecoration.laurel(x: 0.3, y: 0.78, width: 0.4, color: "#FFFFFF", value: "Top 1"))
        let items = refusals([.replace("slots.0.over.deco", with: [laurel])])
        #expect(items.first?.path == "slots.0.over.deco.0.value")
        #expect(items.first?.reason.contains("numbers") == true)
        let good = ScreenshotTemplate.encoded(TemplateDecoration.laurel(x: 0.3, y: 0.78, width: 0.4, color: "#FFFFFF", value: "4.8 ★"))
        #expect(refusals([.replace("slots.0.over.deco", with: [good])]).isEmpty)
    }

    @Test func aShapeNamesItsShapeAndASlotHasAtMostTwelve() {
        let nameless = ScreenshotTemplate.encoded(TemplateDecoration(type: .shape, x: 0.3, y: 0.3, width: 0.4, color: "#FFFFFF", layer: .back))
        #expect(refusals([.replace("deco", with: [nameless])]).first?.path == "deco.0.shape")
        let sparkle = ScreenshotTemplate.encoded(TemplateDecoration.shape(.sparkle, x: 0.3, y: 0.3, width: 0.1, color: "#FFFFFF", layer: .front))
        #expect(refusals([.replace("deco", with: .array(Array(repeating: sparkle, count: 12)))]).isEmpty)
        #expect(refusals([.replace("deco", with: .array(Array(repeating: sparkle, count: 13)))]).map(\.kind) == [.outOfRange])
    }

    @Test func aSlotsOwnBackgroundIsSolidOrLinear() throws {
        let updated = try applied([.replace("slots.2.over.bg", with: ["kind": "solid", "stops": ["#2F2B52"]])])
        #expect(updated.resolved(forSlot: 2).background.stops == ["#2F2B52"])
        #expect(updated.resolved(forSlot: 1).background == template.background)
        let panorama = refusals([.replace("slots.2.over.bg", with: ["kind": "panorama", "stops": ["#000000", "#FFFFFF"]])])
        #expect(panorama.first?.path == "slots.2.over.bg.kind")
        #expect(refusals([.replace("bg", with: ["kind": "solid", "stops": ["#000000"]])]).map(\.kind) == [.unknownPath], "Only a slot overrides bg whole")
    }

    @Test func theDeviceShiftsWithinHalfTheCanvas() {
        #expect(refusals([.replace("slots.0.over.device.dx", with: .double(0.2))]).isEmpty)
        #expect(refusals([.replace("device.dy", with: .double(0.8))]).map(\.kind) == [.outOfRange])
    }
}
