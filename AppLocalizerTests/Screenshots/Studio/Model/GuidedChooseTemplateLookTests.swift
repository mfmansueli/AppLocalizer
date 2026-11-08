//
//  GuidedChooseTemplateLookTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Choose draws a look made from a template pick with that template, the
/// way the Look step and the rendered set do: its Two phones slot has the
/// screen before it standing behind, in the thumbnails and full size.
@MainActor
@Suite("Guided choose · looks from template picks")
struct GuidedChooseTemplateLookTests {
    private static func studio(_ run: AutopilotRun) async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(run)
        return await (StudioTestFixtures.screenshots(center: center), center)
    }

    @Test func eachLookIsItsPickedTemplate() {
        let run = StudioDebugGuided.choosingTemplates
        #expect(run.directions.map(\.template.starter) == [.arcade, .cinema, .editorial])
        for (index, direction) in run.directions.enumerated() {
            #expect(GuidedLookOrigin.pick(of: direction, plan: run.plan)?.number == index + 1)
        }
    }

    @Test func aTwoPhonesSlotHasThePhoneBehind() async throws {
        let run = StudioDebugGuided.choosingTemplates
        let (model, _) = await Self.studio(run)
        let studio = model.studio
        let arcade = try #require(run.directions.first)
        let count = run.plan.screens.count
        var template = arcade.template
        template.slots = AutopilotLocalizer.slots(template.slots, count: count)
        let pairs = (0..<count).filter { template.isPair(slot: $0) }
        try #require(!pairs.isEmpty, "Arcade has a Two phones slot")

        for slot in 0..<count {
            let behind = studio.behindCapture(in: arcade, slot: slot)
            if pairs.contains(slot) {
                let before = run.plan.screens[(slot - 1 + count) % count].id
                #expect(behind?.id == run.pickedCapture(for: before)?.id, "Slot \(slot + 1): the screen before stands behind")
                #expect(behind != nil)
            } else {
                #expect(behind == nil, "Slot \(slot + 1) has one phone")
            }
        }

        let pair = try #require(pairs.first)
        studio.openDirection(arcade, at: pair)
        let viewer = try #require(studio.viewer)
        guard case let .layout(_, _, behind) = viewer.current.content else {
            Issue.record("A direction's screenshot")
            return
        }
        #expect(behind != nil, "Full size too")
    }

    @Test func aOnePhoneTemplateHasNoPhoneBehind() async throws {
        let run = StudioDebugGuided.choosingTemplates
        let (model, _) = await Self.studio(run)
        let cinema = try #require(run.directions.first { $0.template.starter == .cinema })
        for slot in run.plan.screens.indices {
            #expect(model.studio.behindCapture(in: cinema, slot: slot) == nil)
        }
    }
}
#endif
