//
//  GuidedLookOriginTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// After the Look step the picked template's name stays in sight: Choose
/// says which pick each look was made from, and Review which template
/// version the new one replaces.
@MainActor
@Suite("Guided look origin")
struct GuidedLookOriginTests {
    private func plan(picks: [TemplateStarter], style: AutopilotShotStyle = .templates) -> AutopilotPlan {
        var plan = StudioDebugRuns.plan
        plan.screenshotStyle = style
        plan.screenshotTemplates = picks.map(\.title)
        return plan
    }

    private func direction(from starter: TemplateStarter?) -> AutopilotDirection {
        var template = ScreenshotTemplate.starter(starter ?? .above, id: "lumen", title: "Lumen")
        if starter == nil { template.starter = nil }
        return AutopilotDirection(
            id: "a", name: "Quiet Indigo", rationale: "Your indigo.", source: .claudeDesign, client: "Claude Code",
            template: template, receivedAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func aLookFromAPickNamesThePickAndTemplate() {
        let plan = plan(picks: [.cinema, .editorial])
        let text = GuidedLookOrigin.text(for: direction(from: .editorial), plan: plan, brand: "Northpier Brand")
        #expect(text == "Made from your pick 2, the Editorial template, in Northpier Brand.")
        #expect(GuidedLookOrigin.text(for: direction(from: .cinema), plan: plan, brand: nil) == "Made from your pick 1, the Cinema template.")
    }

    @Test func otherLooksSayNothing() {
        #expect(GuidedLookOrigin.text(for: direction(from: .arcade), plan: plan(picks: [.cinema]), brand: nil) == nil, "Not one of the picks")
        #expect(GuidedLookOrigin.text(for: direction(from: nil), plan: plan(picks: [.cinema]), brand: nil) == nil, "Not from a gallery template")
        #expect(GuidedLookOrigin.text(for: direction(from: .cinema), plan: plan(picks: [.cinema], style: .free), brand: nil) == nil, "A look of its own")
    }

    @Test func theReplacedVersionIsTheOneBefore() {
        let template = ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen")
        var history = TemplateHistory.starting(with: template, date: .now, note: "v1")
        var cinema = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        cinema.name = "Quiet Indigo"
        history.save(cinema, date: .now, note: "v2")
        #expect(history.version(before: 2)?.number == 1)
        #expect(history.version(before: 2)?.template.name == template.name)
        #expect(history.version(before: 1) == nil)
        #expect(history.version(before: 9)?.number == 2)
    }
}
