//
//  AutopilotFirstRunScreensTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// An app's first run has no screens yet: the assistant picks them once
/// it's started. Start used to take "no targets" for "everything captured",
/// skip Capture and Claude Code, and make a set with no screenshots.
@MainActor
@Suite("Autopilot · a first run picks its screens")
struct AutopilotFirstRunScreensTests {
    private typealias Fixtures = AutopilotTestFixtures

    /// The small plan with no screens, as AutopilotPlanner makes it for an
    /// app with no screenshot document.
    private static var noScreens: AutopilotPlan {
        var plan = Fixtures.smallPlan
        plan.screens = []
        return plan
    }

    @Test func screenshotsWithNoScreensAwaitThem() {
        #expect(Self.noScreens.awaitsScreens)
        #expect(!Fixtures.smallPlan.awaitsScreens, "It has screens")

        var artworkOnly = Self.noScreens
        artworkOnly.runChoice.makesScreenshots = false
        artworkOnly.alsoMakes.makesArtwork = true
        #expect(!artworkOnly.awaitsScreens, "No screenshots: nothing to pick")
    }

    @Test func startingIsntSkippedToTheDesign() async throws {
        let center = Fixtures.center()
        center.prepare(appID: Fixtures.appID, versionString: "1.0", plan: Self.noScreens)
        center.start(appID: Fixtures.appID)
        let services = Fixtures.services(center)
        await center.skipCapturingIfDone(Fixtures.appID, context: Fixtures.context(services))

        let run = try #require(center.run(for: Fixtures.appID))
        #expect(run.stage == .waiting, "Waits for Claude Code to pick the screens and capture them")
        #expect(run.assistantHasWork)
        #expect(!run.log.map(\.text).contains("Nothing to capture in this run"))
    }

    @Test func theAssistantPicksThemEvenWhenThePersonKeepsTheirs() async throws {
        var plan = Self.noScreens
        plan.choosesScreens = false
        let prompt = AutopilotPrompt.start(appName: "Bruma", appID: Fixtures.appID, plan: plan)
        #expect(prompt.contains("decide which screens show Bruma best"))

        var run = Fixtures.run(.waiting, plan: plan)
        run.captures = []
        let fixtures = MCPAutopilotFixtures(run)
        #expect(try await fixtures.call(GetCapturePlanTool()).result["chooseScreens"] == true)

        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1", "replace": true, "screens": [["name": "Nearby", "steps": "launch → Nearby"]],
        ])
        #expect(outcome.result["status"] == "updated")
        #expect(fixtures.run?.plan.screens.map(\.name) == ["Nearby"])
    }

    @Test func whatToMakeNeverSaysZeroScreenshots() {
        #expect(GuidedMakeSummary.sentence(Self.noScreens) == "You’ll get screenshots in 2 languages.")
        #expect(GuidedMakeSummary.pushed(Self.noScreens) == "screenshots")
    }

    /// MB Admin's first run, screenshots and an App Preview: the plan said
    /// "Records the App Preview in Simulator · about 2 min" and "About 8
    /// min" for the whole run.
    @Test func thePlanCountsTheScreensToCome() throws {
        var plan = Self.noScreens
        plan.alsoMakes.makesAppPreview = true
        plan.runChoice.previewDisplays = [.iPhone]
        let expected = AutopilotEstimate.typicalScreens * plan.displayTypes.count * plan.capturedLocales.count
        #expect(AutopilotEstimate.expectedCaptures(for: plan) == expected)
        #expect(AutopilotEstimate.expectedCaptures(for: Fixtures.smallPlan) == Fixtures.smallPlan.targets.count)

        let capturing = AutopilotEstimate.captureMinutes(for: expected) + AutopilotEstimate.choosingScreensMinutes
        #expect(AutopilotEstimate.captureMinutes(for: plan) == capturing)

        let rows = GuidedPlanTimeline.rows(plan: plan, client: "Claude Code", design: .none, brand: nil)
        let capture = try #require(rows.first { $0.kind == .capture })
        #expect(capture.title == "Captures the screens and records the App Preview in Simulator")
        #expect(capture.time == "about \(capturing + AutopilotEstimate.recordingMinutes(for: plan)) min")
        #expect(GuidedMakeSummary.minutes(plan, design: .none) > capturing)

        #expect(AutopilotEstimate.summary(for: plan, design: .none).hasPrefix("About \(expected) captures in "))
    }
}
#endif
