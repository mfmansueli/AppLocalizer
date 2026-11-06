//
//  GuidedPlanTimelineTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Here's the plan: who does what, the stops numbered, the times "about".
@MainActor
@Suite("GuidedPlanTimeline")
struct GuidedPlanTimelineTests {
    private static func plan(_ change: (inout AutopilotPlan) -> Void = { _ in }) -> AutopilotPlan {
        var plan = AutopilotTestFixtures.smallPlan
        GuidedDefaults.apply(to: &plan)
        change(&plan)
        return plan
    }

    private static func rows(_ plan: AutopilotPlan, design: DesignProjectKind = .claudeDesign, kept: Int = 0) -> [GuidedTimelineRow] {
        GuidedPlanTimeline.rows(plan: plan, client: "Claude Code", design: design, brand: "Northpier Brand", kept: kept)
    }

    @Test func aGuidedPlanStopsTwice() {
        let rows = Self.rows(Self.plan())
        #expect(rows.map(\.kind) == [.capture, .design, .choose, .localize, .review])
        #expect(rows.filter(\.isYours).map(\.time) == ["stop 1 of 2", "stop 2 of 2"])
        #expect(rows[0].title == "Captures 2 screens in Simulator")
        #expect(rows[0].who == .assistant("Claude Code"))
        #expect(rows[0].who.initials == "CC")
        #expect(rows[1].title == "Designs 3 screenshot looks")
        #expect(rows[1].detail == "In Northpier Brand.")
        #expect(rows[1].who == .designer("Claude Design"))
        #expect(rows[3].title == "Localizes and checks everything in 2 languages")
        for row in rows where !row.isYours {
            #expect(row.time.hasPrefix("about "), "Times are estimates: \(row.time)")
        }
        #expect(GuidedPlanTimeline.stopCount(Self.plan()) == 2)
    }

    @Test func choosingForThePersonLeavesTheOnlyStop() {
        let plan = Self.plan { $0.stopsToChoose = false }
        let rows = Self.rows(plan)
        #expect(!rows.contains { $0.kind == .choose })
        #expect(rows.last?.time == "the only stop")
        #expect(GuidedPlanTimeline.stopCount(plan) == 1)
    }

    @Test func pickingTheCapturesIsAThirdStop() {
        let plan = Self.plan { $0.stopsToPick = true }
        let rows = Self.rows(plan)
        #expect(rows.map(\.kind) == [.capture, .pick, .design, .choose, .localize, .review])
        #expect(rows.filter(\.isYours).map(\.time) == ["stop 1 of 3", "stop 2 of 3", "stop 3 of 3"])
        #expect(GuidedPlanTimeline.stopCount(plan) == 3)
    }

    @Test func keepingTheLookHasNothingToChoose() {
        let plan = Self.plan { $0.screenshotStyle = .keep }
        #expect(!GuidedPlanTimeline.hasLookToChoose(plan))
        let rows = Self.rows(plan)
        #expect(!rows.contains { $0.kind == .choose })
        #expect(rows.first { $0.kind == .design }?.title == "Keeps your current look, with the new captures and captions")
    }

    @Test func theStartersDesignInTheIconsColors() {
        var plan = Self.plan()
        plan.alsoMakes.artworkDirection.text = "Calm, like writing before bed"
        let design = Self.rows(plan, design: .none).first { $0.kind == .design }
        #expect(design?.who == .appLocalizer)
        #expect(design?.detail == "From AppLocalizer’s starters, in the app icon’s colors, following what you wrote.")
        #expect(Self.rows(plan).first { $0.kind == .choose }?.detail.contains("Claude’s pick") == true)
        #expect(Self.rows(plan, design: .none).first { $0.kind == .choose }?.detail.contains("AppLocalizer’s pick") == true)
    }

    @Test func templatesDesignOneLookEach() {
        let plan = Self.plan {
            $0.screenshotStyle = .templates
            $0.screenshotTemplates = [TemplateStarter.cinema.title]
        }
        #expect(Self.rows(plan).first { $0.kind == .design }?.title == "Designs 1 screenshot look")
    }

    @Test func reusedCapturesAreNotCapturedAgain() {
        let plan = Self.plan()
        let capture = Self.rows(plan, kept: plan.targets.count).first
        #expect(capture?.title == "Reuses the last captures")
        #expect(capture?.time == "a moment")
    }

    @Test func theSimulatorLineSaysWhatItSetsUp() {
        var plan = Self.plan()
        plan.simulator.overridesStatusBar = true
        plan.simulator.usesSampleData = false
        plan.simulator.lightAppearance = true
        plan.simulator.grantsPermissions = false
        #expect(GuidedPlanTimeline.simulatorLine(plan).hasPrefix("Simulator: status bar 9:41, light appearance"))
        plan.simulator.overridesStatusBar = false
        plan.simulator.lightAppearance = false
        if plan.capturesEachLanguage {
            #expect(GuidedPlanTimeline.simulatorLine(plan) == "Simulator: as it is")
        }
    }
}
#endif
