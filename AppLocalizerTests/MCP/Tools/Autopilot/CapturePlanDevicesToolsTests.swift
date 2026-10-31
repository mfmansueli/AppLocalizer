//
//  CapturePlanDevicesToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Autopilot tools on Apple Watch and Apple Vision Pro: the plan the
/// assistant reads (each device's screens and how to capture them, the
/// languages not on the App Store yet), the watch and Vision Pro screens
/// it writes, and the design brief's canvases.
@MainActor
@Suite("Autopilot tools · devices")
struct CapturePlanDevicesToolsTests {
    private static var waiting: AutopilotRun {
        var run = StudioDebugRuns.run(.waiting, everyDevice: true)
        run.captures = []
        return run
    }

    @Test func thePlanListsEachDevicesScreensAndHowToCaptureThem() async throws {
        let plan = try await MCPAutopilotFixtures(Self.waiting).call(GetCapturePlanTool()).result
        let devices = try #require(plan["devices"]?.arrayValue)
        #expect(devices.map { $0["displayType"] } == ["iphone", "ipad", "watch", "vision"])

        let watch = try #require(devices.first { $0["displayType"] == "watch" })
        #expect(watch["simulator"] == "Apple Watch Ultra 3 (49mm)")
        #expect(watch["pixelSize"] == "422 × 514 (or 410 × 502)")
        #expect(watch["how"]?.stringValue?.contains("xcrun simctl pair") == true)
        #expect(watch["screens"]?.arrayValue?.map { $0["name"] } == ["Mood check-in", "Today’s prompt", "Week", "Watch face"])

        let vision = try #require(devices.first { $0["displayType"] == "vision" })
        #expect(vision["orientation"] == "landscape")
        #expect(vision["screens"]?.arrayValue?.compactMap { $0["sameMomentAs"]?.stringValue } == ["today", "week", "search"])
        #expect(devices.first?["screens"] == nil, "iPhone's screens are the plan's own list")

        let locales = try #require(plan["locales"]?.arrayValue)
        #expect(locales.filter { $0["notOnAppStoreYet"] == true }.compactMap { $0["locale"]?.stringValue } == ["pl", "tr", "he"])
        #expect(plan["total"] == .int(17 * locales.count))
    }

    @Test func theAssistantWritesTheWatchAndVisionProScreens() async throws {
        var run = Self.waiting
        run.plan.setScreens([], on: .watch)
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-debug",
            "screens": [
                ["device": "watch", "name": "Mood", "steps": "LumenWatch → Mood", "caption": "Ignored on the watch"],
                ["device": "watch", "name": "Week", "steps": "LumenWatch → swipe to Week"],
                ["device": "vision", "id": "vision-week", "name": "Week", "steps": "window “Week”"],
                ["device": "vision", "name": "Photos", "steps": "open “Sunday at the lake”", "sameMomentAs": "photos"],
            ],
        ])

        #expect(outcome.result["status"] == "updated")
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens(on: .watch).map(\.id) == ["watch-mood", "watch-week"])
        // A key path inside #expect doesn't compile here (allSatisfy rethrows).
        // swiftformat:disable:next preferKeyPath
        #expect(plan.screens(on: .watch).allSatisfy { $0.caption.isEmpty })
        #expect(plan.screen(id: "vision-week")?.steps == "window “Week”")
        #expect(plan.screen(id: "vision-photos")?.sourceScreenID == "photos")
        #expect(plan.screens.count == 5, "The set's screens are untouched")
        #expect(fixtures.run?.log.last?.text == "Claude Code wrote the steps for 11 screens")
    }

    @Test func aDeviceOutsideThePlanIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.waiting))
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-debug",
            "screens": [["device": "watch", "name": "Mood", "steps": "LumenWatch → Mood"]],
        ])
        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [["name": "Mood", "reason": "Apple Watch isn’t in this plan."]])
        #expect(fixtures.run?.plan.deviceScreens == nil)
    }

    @Test func theBriefDesignsForIPhoneIPadAndVisionProButNotTheWatch() async throws {
        let brief = try await MCPAutopilotFixtures(StudioDebugRuns.run(.design, everyDevice: true)).call(GetDesignBriefTool()).result
        let canvases = try #require(brief["canvases"]?.arrayValue)
        #expect(canvases.map { $0["displayType"] } == ["iphone", "ipad", "vision"])
        #expect(canvases.last?["note"]?.stringValue?.isEmpty == false)
    }

    @Test func reportAppSupportIsOneOfTheTools() {
        #expect(MCPToolbox.standard.tools.contains { $0.definition.name == "report_app_support" })
    }
}
#endif
