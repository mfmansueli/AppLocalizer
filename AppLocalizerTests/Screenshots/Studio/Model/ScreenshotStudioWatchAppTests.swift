//
//  ScreenshotStudioWatchAppTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// An app whose build on App Store Connect gained a watch app, before any
/// assistant reported the project: the Studio shows Apple Watch, the plan
/// says why it's required, and Autopilot plans it, even from an older plan.
@MainActor
@Suite("ScreenshotStudioModel · watch app on App Store Connect")
struct ScreenshotStudioWatchAppTests {
    private static func model(_ run: AutopilotRun? = nil, hasWatchApp: Bool = true) async -> ScreenshotsViewModel {
        await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run), hasWatchApp: hasWatchApp)
    }

    @Test func theStudioShowsAppleWatch() async {
        // The Studio holds its view model unowned: keep each one alive.
        let withWatch = await Self.model()
        #expect(withWatch.studio.devices == [.iPhone, .iPhoneDuo, .iPad, .watch])
        let without = await Self.model(hasWatchApp: false)
        #expect(without.studio.devices == [.iPhone, .iPhoneDuo, .iPad])
    }

    @Test func thePlanSaysWhereItFoundTheWatchApp() async {
        let model = await Self.model(StudioDebugRuns.run(.plan))
        let plan = StudioDebugRuns.plan
        #expect(model.studio.planFoundText == "Found in Lumen Journal 1.4 on App Store Connect: its build has an Apple Watch app.")
        #expect(model.studio.planDevices(plan) == [.iPhone, .iPhoneDuo, .iPad, .watch])
        #expect(model.studio.planDeviceDetail(.watch, plan: plan)
            == "422 × 514 · Ultra 3 · required: the 1.4 build has an Apple Watch app. You’ll need to upload these by hand before submitting.")
    }

    @Test func withAVisionOSVersionTooBothAreNamed() async {
        let model = await StudioTestFixtures.screenshots(center: nil, hasVisionVersion: true, hasWatchApp: true)
        #expect(model.studio.planFoundText
            == "Found in Lumen Journal 1.4 on App Store Connect: its build has an Apple Watch app, and it has a visionOS version.")
    }

    @Test func runAutopilotPlansTheWatch() async throws {
        let model = await Self.model()
        model.studio.runAutopilot()
        let plan = try #require(model.studio.run?.plan)
        #expect(plan.displayTypes.contains(.watch))
        #expect(model.studio.planDeviceDetail(.watch, plan: plan) == "422 × 514 · Ultra 3 · required: the 1.4 build has an Apple Watch app")
    }

    // MARK: - An older plan

    @Test func aPlanFromBeforeTheWatchAppGainsIt() {
        var previous = StudioDebugRuns.run(.ready)
        previous.plan.setScreens([AutopilotScreen(id: "vision-today", name: "Today", sourceScreenID: "today")], on: .visionPro)
        previous.plan.setPlans(.visionPro, true)
        let plan = Self.plan(previous: previous, support: AutopilotSupport(devices: [.watch, .visionPro]))
        #expect(plan.displayTypes == [.iPhone, .iPad, .watch, .visionPro])
        #expect(plan.screens(on: .visionPro).map(\.id) == ["vision-today"], "The person's windows are kept")
    }

    @Test func aDeviceThePersonTurnedOffStaysOff() {
        var previous = StudioDebugRuns.run(.ready)
        previous.plan.setPlans(.watch, true)
        previous.plan.setPlans(.watch, false)
        #expect(previous.plan.leftOutDevices == [.watch])
        let plan = Self.plan(previous: previous, support: AutopilotSupport(devices: [.watch]))
        #expect(plan.displayTypes == [.iPhone, .iPad])

        previous.plan.setPlans(.watch, true)
        #expect(previous.plan.leftOutDevices == nil)
    }

    @Test func theSupportCountsTheBuildsWatchApp() {
        let support = AutopilotSupport.make(
            profile: nil, declined: [], storeLocales: ["en-US"], hasVisionVersion: false, hasWatchApp: true, live: LiveScreenshots()
        )
        #expect(support.devices == [.watch])
    }

    private static func plan(previous: AutopilotRun, support: AutopilotSupport) -> AutopilotPlan {
        AutopilotPlanner.plan(
            document: nil, live: LiveScreenshots(), primaryLocale: .englishUS, localeCodes: ["en-US"], previous: previous, support: support
        )
    }
}
#endif
