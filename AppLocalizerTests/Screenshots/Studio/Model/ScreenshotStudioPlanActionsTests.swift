//
//  ScreenshotStudioPlanActionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Autopilot sheet's Plan and Capture-waiting actions: editing the
/// plan, Cancel, Stop, and the prompt for the assistant.
@MainActor
@Suite("ScreenshotStudioModel · Plan")
struct ScreenshotStudioPlanActionsTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    @Test func anOpenPlanCanBeEdited() async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.plan))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.updatePlan { plan in
            plan.stopsToPick = false
            plan.displayTypes.hasIPad = false
        }
        #expect(center.run(for: appID)?.plan.stopsToPick == false)
        #expect(center.run(for: appID)?.plan.displayTypes == [.iPhone])
    }

    @Test func aRunningPlanIsLeftAlone() async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.capture))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.updatePlan { $0.stopsToPick = false }
        #expect(center.run(for: appID)?.plan.stopsToPick == true)
    }

    @Test func cancellingTheFirstPlanForgetsIt() async {
        let center = StudioTestFixtures.center()
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.runAutopilot()
        #expect(center.run(for: appID)?.stage == .plan)
        model.studio.cancelPlan()
        #expect(center.run(for: appID) == nil)
        #expect(!model.studio.isAutopilotPresented)
    }

    @Test func cancellingANewPlanBringsBackTheLastRun() async {
        let ready = StudioDebugRuns.run(.ready)
        let center = StudioTestFixtures.center(ready)
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.runAutopilot()
        #expect(center.run(for: appID)?.id != ready.id)
        #expect(center.run(for: appID)?.stage == .plan)
        model.studio.cancelPlan()
        #expect(center.run(for: appID) == ready)
        #expect(!model.studio.isAutopilotPresented)
    }

    @Test func runAutopilotKeepsARunInProgress() async {
        let capturing = StudioDebugRuns.run(.capture)
        let center = StudioTestFixtures.center(capturing)
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.runAutopilot()
        #expect(center.run(for: appID) == capturing)
        #expect(model.studio.isAutopilotPresented)
    }

    @Test func stopGoesBackToThePlanKeepingTheCaptures() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.failing)
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.viewedStep = .capture
        model.studio.stop()
        let run = try #require(center.run(for: appID))
        #expect(run.stage == .plan)
        #expect(run.openProblems.isEmpty)
        #expect(run.keptCaptureCount == 76)
        #expect(model.studio.viewedStep == nil)
    }

    @Test func cancelRunWhileWaitingGoesBackToThePlan() async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.waiting))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.stop()
        #expect(center.run(for: appID)?.stage == .plan)
        #expect(model.studio.shownStep == .plan)
    }

    // MARK: - Prompt

    @Test func withoutARunThereIsOnlyTheShortcut() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center())
        #expect(model.studio.prompt.isEmpty)
        #expect(ScreenshotStudioModel.promptShortcut == "/mcp__applocalizer__run_screenshots")
    }

    @Test func thePromptAsksTheAssistantToPickTheScreens() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.plan)))
        let devices = ["iPhone", "iPad"].formatted(.list(type: .and))
        #expect(model.studio.prompt == "Run Lumen Journal’s screenshot plan from AppLocalizer: decide which screens show Lumen Journal best, "
            + "build the app, capture them on \(devices) in all 12 languages, and send the captures back. "
            + "Start with get_capture_plan for app 6450000001, then ask next_step after each step.")
    }

    @Test func keepingTheScreensNamesThem() async {
        var run = StudioDebugRuns.run(.plan)
        run.plan.choosesScreens = false
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        #expect(model.studio.prompt.hasPrefix("Run Lumen Journal’s screenshot plan from AppLocalizer: build the app, capture the 5 screens on"))
    }

    @Test func aPlanInOneLanguageSaysSo() async {
        var run = StudioDebugRuns.run(.plan)
        run.plan.choosesScreens = false
        run.plan.localeCodes = ["en-US"]
        run.plan.displayTypes = [.iPhone]
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        #expect(model.studio.prompt.contains("capture the 5 screens on iPhone in 1 language, and send"))
    }

    @Test func everyDeviceAndTheAppsOwnLanguagesAreNamed() async {
        var run = StudioDebugRuns.run(.plan)
        run.plan.choosesScreens = false
        run.plan.displayTypes = [.iPhone, .iPad, .watch, .visionPro]
        run.plan.setScreens([AutopilotScreen(name: "Mood check-in")], on: .watch)
        run.plan.newLocaleCodes = ["pl", "tr", "he"]
        run.plan.setIncludesNewLanguages(true)
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
        let devices = ["iPhone", "iPad", "Apple Watch", "Apple Vision Pro"].formatted(.list(type: .and))
        #expect(model.studio.prompt.hasPrefix(
            "Run Lumen Journal’s screenshot plan from AppLocalizer: build the app, capture every screen on \(devices) in all 15 languages the app supports, and send the captures back."
        ))
    }
}
#endif
