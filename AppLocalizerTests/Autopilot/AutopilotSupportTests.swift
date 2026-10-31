//
//  AutopilotSupportTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What a new plan knows about the devices and languages the app supports,
/// and the plan Run Autopilot… opens with because of it.
@MainActor
@Suite("Autopilot support")
struct AutopilotSupportTests {
    private static let storeLocales = StorePageSampleData.presentLocales.map(\.code)

    // MARK: - AutopilotSupport.make

    @Test func theProjectsReportNamesDevicesAndNewLanguages() {
        let support = AutopilotSupport.make(
            profile: DebugAppSupport.lumen, declined: [], storeLocales: Self.storeLocales,
            hasVisionVersion: false, live: LiveScreenshots()
        )
        #expect(support.devices == [.iPad, .watch, .visionPro])
        #expect(support.newLocaleCodes == ["pl", "tr", "he"])
    }

    @Test func aLanguageSaidNotNowToIsLeftOut() {
        let support = AutopilotSupport.make(
            profile: DebugAppSupport.lumen, declined: ["tr"], storeLocales: Self.storeLocales,
            hasVisionVersion: false, live: LiveScreenshots()
        )
        #expect(support.newLocaleCodes == ["pl", "he"])
    }

    @Test func withoutAReportAppStoreConnectStillTells() {
        let watchSet = LiveScreenshotSet(
            id: "set|watch", locale: "en-US", displayType: .watch,
            screenshots: [LiveScreenshot(id: "w1", fileName: "", checksum: "w1")]
        )
        let support = AutopilotSupport.make(
            profile: nil, declined: [], storeLocales: Self.storeLocales,
            hasVisionVersion: true, live: LiveScreenshots(screenshotSets: [watchSet])
        )
        #expect(support.devices == [.watch, .visionPro])
        #expect(support.newLocaleCodes.isEmpty)

        let emptyWatchSet = LiveScreenshotSet(id: "set|watch", locale: "en-US", displayType: .watch, screenshots: [])
        let none = AutopilotSupport.make(
            profile: nil, declined: [], storeLocales: [], hasVisionVersion: false, live: LiveScreenshots(screenshotSets: [emptyWatchSet])
        )
        #expect(none == .none)
    }

    // MARK: - Planner

    @Test func aFirstPlanCoversEveryDeviceAndTheNewLanguages() {
        let support = AutopilotSupport(devices: [.watch, .visionPro], newLocaleCodes: ["pl", "he"])
        let plan = AutopilotPlanner.plan(
            document: ScreenshotsDebugDocuments.standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US", "de-DE"], previous: nil, support: support
        )
        #expect(plan.displayTypes == [.iPhone, .iPad, .watch, .visionPro])
        #expect(plan.localeCodes == ["en-US", "de-DE", "pl", "he"])
        #expect(plan.addedLocaleCodes == ["pl", "he"])
        #expect(plan.newLocaleCodes == ["pl", "he"])
        #expect(plan.screens(on: .watch).isEmpty, "The assistant finds the watch screens")
        #expect(plan.screens(on: .visionPro).map(\.sourceScreenID) == ["today-1", "week-2", "search-3"])
        #expect(plan.screens(on: .visionPro).first?.caption == plan.screens.first?.caption)
    }

    @Test func runningAgainAddsDevicesOnceAndKeepsTheNewLanguagesLeftOut() {
        var previous = StudioDebugRuns.run(.ready)
        previous.plan.newLocaleCodes = ["pl"]
        let support = AutopilotSupport(devices: [.visionPro], newLocaleCodes: ["pl"])
        let plan = AutopilotPlanner.plan(
            document: ScreenshotsDebugDocuments.standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US", "fr-FR"], previous: previous, support: support
        )
        #expect(plan.displayTypes == [.iPhone, .iPad, .visionPro])
        #expect(plan.screens(on: .visionPro).count == AutopilotPlanner.visionScreenCount)
        #expect(plan.localeCodes == ["en-US", "fr-FR"], "Left out last time, so left out again")
        #expect(plan.newLocaleCodes == ["pl"])

        var edited = StudioDebugRuns.run(.ready, everyDevice: true)
        edited.plan.setScreens([AutopilotScreen(id: "vision-today", name: "Today", sourceScreenID: "today")], on: .visionPro)
        let again = AutopilotPlanner.plan(
            document: ScreenshotsDebugDocuments.standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US"], previous: edited, support: support
        )
        #expect(again.screens(on: .visionPro).count == 1, "The person's own windows are kept")
        #expect(again.screens(on: .watch).count == 4)
    }

    @Test func iPadIsPlannedWhenTheProjectSaysTheAppRunsThere() {
        var phoneOnly = ScreenshotsDocument.empty(primary: "en-US")
        phoneOnly.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 0))
        let without = AutopilotPlanner.devices(document: phoneOnly, live: LiveScreenshots(), support: .none)
        #expect(without == [.iPhone])
        let with = AutopilotPlanner.devices(document: phoneOnly, live: LiveScreenshots(), support: AutopilotSupport(devices: [.iPad]))
        #expect(with == [.iPhone, .iPad])
    }
}
#endif
