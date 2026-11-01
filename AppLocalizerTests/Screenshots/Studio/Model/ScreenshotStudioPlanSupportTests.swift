//
//  ScreenshotStudioPlanSupportTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Plan step's devices and languages: where AppLocalizer found them,
/// why each device is required, turning one off, and the project's
/// languages the App Store page doesn't have yet.
@MainActor
@Suite("ScreenshotStudioModel · Plan support")
struct ScreenshotStudioPlanSupportTests {
    private static let storeCodes = StorePageSampleData.presentLocales.map(\.code)

    /// The Studio of Lumen with its project reported, the App Store page's
    /// ten languages, and `run`.
    private static func model(_ run: AutopilotRun?, support: AppSupportCenter? = DebugAppSupport.center()) async -> ScreenshotsViewModel {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run), support: support)
        model.studio.storeTexts = StudioTestFixtures.storeTexts(storeCodes)
        return model
    }

    @Test func thePlanSaysWhereTheDevicesAndLanguagesWereFound() async {
        let model = await Self.model(StudioDebugRuns.run(.plan, everyDevice: true))
        #expect(model.studio.planFoundText == "Found in Lumen Journal 1.4 on App Store Connect and in the Xcode project: "
            + "targets Lumen (iOS, visionOS) and LumenWatch Watch App, and 13 languages in Localizable.xcstrings, 10 of them on the App Store.")

        let unreported = await Self.model(StudioDebugRuns.run(.plan), support: nil)
        #expect(unreported.studio.planFoundText == nil)
    }

    @Test func eachDeviceSaysWhyItsRequired() async {
        let model = await Self.model(StudioDebugRuns.run(.plan, everyDevice: true))
        let studio = model.studio
        let plan = studio.run?.plan ?? StudioDebugRuns.everyDevicePlan
        #expect(plan.displayTypes.contains(.iPhoneDuo))
        #expect(studio.planDevices(plan) == [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro])
        #expect(studio.planDeviceDetail(.iPhone, plan: plan) == "1320 × 2868 · required for every iPhone app")
        #expect(studio.planDeviceDetail(.iPad, plan: plan) == "2752 × 2064 · required: Lumen runs on iPad")
        #expect(studio.planDeviceDetail(.watch, plan: plan) == "422 × 514 · Ultra 3 · required: Lumen has a watch app, LumenWatch")
        #expect(studio.planDeviceDetail(.visionPro, plan: plan) == "3840 × 2160 · required: 1.4 adds visionOS")
        #expect(studio.planDeviceDetail(.iPhoneDuo, plan: plan)
            == "2007 × 2853 · inner display · required from April 2027 for apps built with the iOS 27.1 SDK")
    }

    /// iPhone Duo is Apple's rule from April 2027: planned from the start,
    /// and turned off it's left to upload by hand like any required device.
    @Test func iPhoneDuoIsPlannedAndTurnedOffIsLeftToUploadByHand() async {
        let model = await Self.model(StudioDebugRuns.run(.plan))
        #expect(model.studio.run?.plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad])
        #expect(model.studio.requiredReason(.iPhoneDuo) == "from April 2027 for apps built with the iOS 27.1 SDK")
        model.studio.setPlans(.iPhoneDuo, false)
        let off = model.studio.run?.plan ?? StudioDebugRuns.plan
        #expect(!off.displayTypes.contains(.iPhoneDuo))
        #expect(model.studio.planDeviceDetail(.iPhoneDuo, plan: off) == "2007 × 2853 · inner display · "
            + "required from April 2027 for apps built with the iOS 27.1 SDK. You’ll need to upload these by hand before submitting.")
    }

    @Test func turningOffARequiredDeviceLeavesItToBeUploadedByHand() async {
        let model = await Self.model(StudioDebugRuns.run(.plan, everyDevice: true))
        model.studio.setPlans(.watch, false)
        let plan = model.studio.run?.plan ?? StudioDebugRuns.everyDevicePlan
        #expect(plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad, .visionPro])
        #expect(model.studio.planDeviceDetail(.watch, plan: plan)
            == "422 × 514 · Ultra 3 · required: Lumen has a watch app, LumenWatch. You’ll need to upload these by hand before submitting.")
    }

    @Test func withoutAReportIPadIsLandscapeAndVisionFollowsAppStoreConnect() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.plan)), hasVisionVersion: true)
        let plan = StudioDebugRuns.plan
        #expect(model.studio.planDevices(plan) == [.iPhone, .iPhoneDuo, .iPad, .visionPro])
        #expect(model.studio.planDeviceDetail(.iPad, plan: plan) == "2752 × 2064 · landscape")
        #expect(model.studio.planDeviceDetail(.visionPro, plan: plan)
            == "3840 × 2160 · required: 1.4 has a visionOS version. You’ll need to upload these by hand before submitting.")
    }

    @Test func turningOnAppleVisionProStartsWithTheFirstIPhoneScreens() async {
        let model = await Self.model(StudioDebugRuns.run(.plan))
        model.studio.setPlans(.visionPro, true)
        let plan = model.studio.run?.plan
        #expect(plan?.displayTypes == [.iPhone, .iPhoneDuo, .iPad, .visionPro])
        #expect(plan?.screens(on: .visionPro).map(\.sourceScreenID) == ["today", "week", "search"])
    }

    @Test func theProjectsNewLanguagesCanBeLeftOut() async {
        let model = await Self.model(StudioDebugRuns.run(.plan, everyDevice: true))
        let studio = model.studio
        let plan = StudioDebugRuns.everyDevicePlan
        #expect(studio.storeLanguagesTitle(plan) == "All \(plan.localeCodes.count - 3) languages on the App Store")
        #expect(studio.newLanguagesTitle(plan) == "3 more the app supports: Polish, Turkish, and Hebrew")
        #expect(studio.newLanguagesDetail
            == "In Localizable.xcstrings but not on the App Store yet. Store Page suggests creating their pages; they’re created when you push.")
        #expect(studio.newLanguagesTitle(StudioDebugRuns.plan) == nil)

        studio.setIncludesNewLanguages(false)
        #expect(studio.run?.plan.includesNewLanguages == false)
        #expect(studio.run?.plan.localeCodes.contains("pl") == false)
    }

    @Test func runAutopilotPlansWhatTheProjectSupports() async throws {
        let model = await Self.model(nil)
        model.studio.runAutopilot()
        let plan = try #require(model.studio.run?.plan)
        #expect(plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro])
        #expect(plan.addedLocaleCodes == ["pl", "tr", "he"])
        #expect(plan.screens(on: .visionPro).count == AutopilotPlanner.visionScreenCount)

        let declined = await Self.model(nil, support: DebugAppSupport.center(declined: ["tr"]))
        declined.studio.runAutopilot()
        #expect(declined.studio.run?.plan.addedLocaleCodes == ["pl", "he"])
    }

    @Test func theDevicesShownFollowTheProjectAndTheSet() async {
        let reported = await Self.model(nil)
        #expect(reported.studio.devices == [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro])
        let plain = await Self.model(nil, support: nil)
        #expect(plain.studio.devices == [.iPhone, .iPhoneDuo, .iPad])
        let everyDevice = await StudioTestFixtures.screenshots(center: nil, document: DebugEveryDevice.document)
        #expect(everyDevice.studio.devices == [.iPhone, .iPhoneDuo, .iPad, .watch, .visionPro])
    }
}
#endif
