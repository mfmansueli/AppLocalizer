//
//  AutopilotPlanDevicesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A plan on Apple Watch and Apple Vision Pro as well as iPhone and iPad:
/// each device's screens, what's captured, which pick a screen follows,
/// the app's languages that aren't on the App Store yet, and editing a
/// screen on whichever device has it.
@MainActor
@Suite("AutopilotPlan · devices")
struct AutopilotPlanDevicesTests {
    private static var plan: AutopilotPlan { StudioDebugRuns.everyDevicePlan }

    @Test func iPhoneAndIPadShareTheSetsScreensAndTheOthersHaveTheirOwn() {
        let plan = Self.plan
        #expect(plan.displayTypes == [.iPhone, .iPad, .watch, .visionPro])
        #expect(plan.screens(on: .iPhone).count == 5)
        #expect(plan.screens(on: .iPad) == plan.screens)
        #expect(plan.screens(on: .watch).map(\.name) == ["Mood check-in", "Today’s prompt", "Week", "Watch face"])
        #expect(plan.screens(on: .visionPro).map(\.sourceScreenID) == ["today", "week", "search"])
        #expect(plan.screensPerLanguage == 17)
        #expect(plan.targets.count == 17 * plan.localeCodes.count)
        #expect(plan.targets.last == AutopilotCaptureTarget(screenID: "vision-search", displayType: .visionPro, locale: plan.localeCodes.last ?? ""))
    }

    @Test func theScopeCountsScreensPerLanguage() {
        let plan = Self.plan
        let devices = ["iPhone", "iPad", "Apple Watch", "Apple Vision Pro"].formatted(.list(type: .and))
        #expect(plan.devicesTitle == devices)
        #expect(plan.scopeTitle == "\(devices) · \(plan.localeCodes.count) languages · 17 screens per language")
    }

    @Test func devicesAreAddedInTheStudiosOrderAndIPhoneStays() {
        var plan = AutopilotTestFixtures.singlePlan()
        plan.setPlans(.visionPro, true)
        plan.setPlans(.iPad, true)
        plan.setPlans(.watch, true)
        #expect(plan.displayTypes == [.iPhone, .iPad, .watch, .visionPro])
        plan.setPlans(.iPhone, false)
        plan.setPlans(.watch, false)
        #expect(plan.displayTypes == [.iPhone, .iPad, .visionPro])
    }

    @Test func aScreenIsFoundOnItsDeviceAndAWindowFollowsItsIPhonePick() {
        let plan = Self.plan
        #expect(plan.display(of: "week") == .iPhone)
        #expect(plan.display(of: "watch-week") == .watch)
        #expect(plan.display(of: "vision-week") == .visionPro)
        #expect(plan.slot(of: "watch-watch-face") == 3)
        #expect(plan.slot(of: "vision-search") == 2)
        #expect(plan.pickScreenID(for: "vision-week") == "week")
        #expect(plan.pickScreenID(for: "watch-week") == "watch-week")
        #expect(plan.pickedScreens.count == 9, "The set's five and the watch's four; Apple Vision Pro follows iPhone")
    }

    @Test func theAppsNewLanguagesCanBeLeftOut() {
        var plan = Self.plan
        #expect(plan.addedLocaleCodes == ["pl", "tr", "he"])
        #expect(plan.includesNewLanguages)
        let all = plan.localeCodes.count
        plan.setIncludesNewLanguages(false)
        #expect(!plan.includesNewLanguages)
        #expect(plan.localeCodes.count == all - 3)
        plan.setIncludesNewLanguages(true)
        plan.setIncludesNewLanguages(true)
        #expect(plan.localeCodes.count == all, "Including twice adds them once")
    }

    @Test func aScreenIsEditedOnWhicheverDeviceHasIt() {
        var plan = Self.plan
        plan.updateScreen(id: "watch-week") { $0.steps = "LumenWatch → Week" }
        plan.updateScreen(id: "today") { $0.caption = "Write daily" }
        #expect(plan.screen(id: "watch-week")?.steps == "LumenWatch → Week")
        #expect(plan.screens[0].caption == "Write daily")

        plan.appendScreen(AutopilotScreen(id: "watch-streak", name: "Streak"), on: .watch)
        #expect(plan.screens(on: .watch).last?.id == "watch-streak")
        plan.removeScreen(id: "watch-streak")
        plan.removeScreen(id: "vision-search")
        #expect(plan.screens(on: .watch).count == 4)
        #expect(plan.screens(on: .visionPro).count == 2)
    }

    @Test func aWindowWithoutACaptionShowsItsIPhoneScreensCaption() {
        let plan = Self.plan
        let window = AutopilotScreen(id: "vision-week", name: "Week", sourceScreenID: "week")
        #expect(plan.caption(of: window) == plan.screens[1].caption)
        #expect(plan.caption(of: AutopilotScreen(name: "Own", caption: "Mine", sourceScreenID: "week")) == "Mine")
        #expect(plan.caption(of: AutopilotScreen(name: "Lost", sourceScreenID: "gone")).isEmpty)
    }
}
#endif
