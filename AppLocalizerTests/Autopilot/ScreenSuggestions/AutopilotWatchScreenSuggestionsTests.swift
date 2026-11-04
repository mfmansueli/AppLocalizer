//
//  AutopilotWatchScreenSuggestionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Suggest Screens for Apple Watch: asked for the watch's own screens,
/// answered without captions, and added after the watch's screens, not the
/// set's. Each device has Apple's 10.
@MainActor
@Suite("Autopilot screen suggestions · Apple Watch")
struct AutopilotWatchScreenSuggestionsTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = StudioDebugRuns.appID
    private let client = AutopilotTestFixtures.client

    private var run: AutopilotRun? { center.run(for: appID) }

    /// The watch suggestions with a caption each, as an assistant might
    /// send them.
    private var captionedWatchSuggestions: [AutopilotScreenSuggestion] {
        StudioDebugAddScreens.watchSuggestions.map { suggestion in
            var suggestion = suggestion
            suggestion.caption = "On your wrist"
            return suggestion
        }
    }

    private func askForTheWatch(_ ask: String? = nil) {
        center.install(StudioDebugRuns.run(.plan, everyDevice: true))
        center.requestScreenSuggestions(appID: appID, ask: ask, on: .watch)
    }

    @Test func askingForWatchScreensSaysWhichDevice() async {
        askForTheWatch("one with the complication")
        let request = AutopilotScreenRequest(ask: "one with the complication", askedAt: AutopilotTestFixtures.now, displayType: .watch)
        #expect(run?.screenRequest == request)
        #expect(request.device == .watch)
        #expect(await center.nextStep(appID: appID, client: client) == .suggestScreens(request))
    }

    @Test func theSetsRequestNamesNoDevice() {
        center.install(StudioDebugRuns.run(.plan, everyDevice: true))
        center.requestScreenSuggestions(appID: appID, ask: nil, on: .iPad)
        #expect(run?.screenRequest?.displayType == nil)
        #expect(run?.screenRequest?.device == .iPhone, "iPhone stands for the set")
    }

    @Test func onlyAPlannedWatchIsAskedFor() {
        center.install(StudioDebugRuns.run(.plan))
        center.requestScreenSuggestions(appID: appID, ask: nil, on: .watch)
        #expect(run?.screenRequest == nil, "The plan has no Apple Watch")
        center.install(StudioDebugRuns.run(.plan, everyDevice: true))
        center.requestScreenSuggestions(appID: appID, ask: nil, on: .visionPro)
        #expect(run?.screenRequest == nil, "Apple Vision Pro's windows show the iPhone screens")
    }

    @Test func watchSuggestionsComeWithoutCaptions() throws {
        askForTheWatch()
        let received = try center.receiveScreenSuggestions(captionedWatchSuggestions, client: client, appID: appID)
        #expect(received.device == .watch)
        let captions = received.items.map(\.caption)
        #expect(captions == ["", "", ""], "Watch screenshots have no captions")
        #expect(run?.screenSuggestions?.displayType == .watch)
    }

    @Test func addToPlanPutsItAfterTheWatchsScreens() throws {
        askForTheWatch()
        try center.receiveScreenSuggestions(captionedWatchSuggestions, client: client, appID: appID)
        center.addSuggestedScreen("sg-watch-stack", appID: appID)

        let plan = try #require(run?.plan)
        #expect(plan.screens.count == 5, "The set's screens stay as they are")
        let watch = plan.screens(on: .watch)
        #expect(watch.count == 5)
        #expect(watch.last == AutopilotScreen(
            id: "watch-smart-stack-widget", name: "Smart Stack widget",
            steps: "watch face → turn the crown to the Smart Stack → Lumen streak widget", origin: .suggestion(client: client)
        ))
        let watchTargets = plan.targets.filter { $0.screenID == "watch-smart-stack-widget" }.map(\.displayType)
        #expect(!watchTargets.isEmpty)
        #expect(Set(watchTargets) == [.watch], "Captured on the watch only")
        #expect(run?.screenSuggestions?.items[1].status == .added)
    }

    @Test func eachDeviceHasItsOwnTen() {
        var full = StudioDebugRuns.run(.plan, everyDevice: true)
        for index in 6...10 { full.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        center.install(full)
        center.requestScreenSuggestions(appID: appID, ask: nil)
        #expect(run?.screenRequest == nil, "The set is full")
        center.requestScreenSuggestions(appID: appID, ask: nil, on: .watch)
        #expect(run?.screenRequest?.device == .watch, "The watch still has room")
        #expect(run?.plan.screenRoom(on: .watch) == 6)
        #expect(run?.plan.screenRoom(on: .iPhone) == 0)

        var watchFull = StudioDebugRuns.run(.plan, everyDevice: true)
        for index in 5...10 {
            watchFull.plan.appendScreen(AutopilotScreen(id: "watch-screen-\(index)", name: "Screen \(index)", steps: "launch"), on: .watch)
        }
        center.install(watchFull)
        center.requestScreenSuggestions(appID: appID, ask: nil, on: .watch)
        #expect(run?.screenRequest == nil, "Apple's 10 on the watch")
    }

    @Test func aDraftOnTheWatchHasNoCaption() {
        var draft = AutopilotScreenDraft(name: "Mood history", caption: "Typed before", displayType: .watch)
        #expect(draft.screen(id: "watch-mood-history").caption.isEmpty)
        draft.displayType = .iPhone
        #expect(draft.screen(id: "mood-history").caption == "Typed before")
    }

    @Test func thePromptAsksForWatchScreens() {
        let prompt = AutopilotPrompt.suggestScreens(appName: "Lumen Journal", appID: appID, ask: "", on: .watch)
        #expect(prompt.hasPrefix("Suggest new Apple Watch screens for Lumen Journal’s screenshot plan"))
        #expect(AutopilotPrompt.suggestScreens(appName: "Lumen Journal", appID: appID, ask: "").hasPrefix("Suggest new screens for"))
    }

    @Test func onlyTheSetAndAPlannedWatchTakeNewScreens() {
        let plan = StudioDebugRuns.plan
        #expect(plan.takesNewScreens(on: .iPhone))
        #expect(plan.takesNewScreens(on: .iPad))
        #expect(!plan.takesNewScreens(on: .watch))
        let every = StudioDebugRuns.everyDevicePlan
        #expect(every.takesNewScreens(on: .watch))
        #expect(!every.takesNewScreens(on: .visionPro))
    }
}
#endif
