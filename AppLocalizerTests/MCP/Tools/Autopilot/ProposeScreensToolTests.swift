//
//  ProposeScreensToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Suggest Screens over MCP: `next_step` asks for them at the plan,
/// `propose_screens` shows them, and the screens the person added are the
/// assistant's to work out and keep. Sent outside Suggest Screens, with or
/// without a run, they wait for the app's next plan.
@MainActor
@Suite("Autopilot tools · suggest screens")
struct ProposeScreensToolTests {
    private static var asked: AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        run.screenRequest = AutopilotScreenRequest(ask: "one that shows the streak", askedAt: AutopilotTestFixtures.now)
        return run
    }

    /// Lumen on every device, asked for Apple Watch screens.
    private static var askedForTheWatch: AutopilotRun {
        var run = StudioDebugRuns.run(.plan, everyDevice: true)
        run.screenRequest = AutopilotScreenRequest(ask: nil, askedAt: AutopilotTestFixtures.now, displayType: .watch)
        return run
    }

    private static let screens: JSONValue = [
        [
            "name": "Streak widget", "reason": "Lumen ships a widget.", "evidence": "LumenWidget target",
            "steps": "add LumenWidget (medium) to the Home Screen", "caption": "Your streak, on your Home Screen",
        ],
        ["name": "Insights", "reason": "New in 1.4.", "steps": "tab “Insights”"],
    ]

    @Test func nextStepAsksForScreensWithWhatThePlanHas() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asked)
        let result = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(result["action"] == "suggest_screens")
        #expect(result["ask"] == "one that shows the streak")
        #expect(result["device"] == "set")
        #expect(result["room"] == 5)
        #expect(result["version"] == "1.4")
        #expect(result["screens"]?.arrayValue?.first == ["slot": 1, "name": "Today", "steps": .string(StudioDebugRuns.steps[0])])
        let how = try #require(result["how"]?.stringValue)
        #expect(how.contains("Suggest up to 3 screens"))
        #expect(how.contains("LumenUITests/ScreenshotTests.swift"))
        #expect(how.contains("propose_screens"))
        #expect(fixtures.run?.stage == .plan, "Asking doesn't start the run")
    }

    @Test func theSuggestionsAreShownInThePlan() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asked)
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["status"] == "shown")
        #expect(outcome.result["count"] == 2)
        let suggestions = try #require(fixtures.run?.screenSuggestions)
        #expect(suggestions.ask == "one that shows the streak")
        #expect(suggestions.client == AutopilotTestFixtures.client)
        #expect(suggestions.items.map(\.name) == ["Streak widget", "Insights"])
        #expect(suggestions.items.first?.evidence == "LumenWidget target")
        #expect(suggestions.items.last?.caption == "", "Localize writes a missing caption")
        #expect(Set(suggestions.items.map(\.id)).count == 2)
        #expect(fixtures.run?.plan.screens.count == 5, "Nothing is added on its own")

        let done = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(done["action"] == "done")
        #expect(done["say"]?.stringValue?.contains("the person adds the ones they want") == true)
    }

    @Test func nextStepAsksForTheWatchsOwnScreens() async throws {
        let fixtures = MCPAutopilotFixtures(Self.askedForTheWatch)
        let result = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(result["action"] == "suggest_screens")
        #expect(result["device"] == "watch")
        #expect(result["room"] == 6, "Apple's 10 less the watch's 4")
        #expect(result["screens"]?.arrayValue?.count == 4)
        #expect(result["screens"]?.arrayValue?.first == ["slot": 1, "name": "Mood check-in", "steps": "LumenWatch → Mood"])
        let how = try #require(result["how"]?.stringValue)
        #expect(how.contains("Suggest up to 3 Apple Watch screens"))
        #expect(how.contains("Leave out caption"))
        #expect(how.contains("propose_screens"))
    }

    @Test func watchSuggestionsAreShownUnderTheWatchWithoutCaptions() async throws {
        let fixtures = MCPAutopilotFixtures(Self.askedForTheWatch)
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["status"] == "shown")
        let suggestions = try #require(fixtures.run?.screenSuggestions)
        #expect(suggestions.device == .watch)
        #expect(suggestions.items.first?.caption == "", "Watch screenshots have no captions")
        #expect(fixtures.run?.plan.screens(on: .watch).count == 4, "Nothing is added on its own")
    }

    @Test func onlyAsManyAsThereIsRoomFor() async throws {
        var run = Self.asked
        for index in 6...9 { run.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["count"] == 1)
    }

    /// The plan is open but nobody pressed Suggest Screens: they wait in it
    /// with Add to Plan all the same.
    @Test func suggestionsNobodyAskedForWaitInTheOpenPlan() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.plan))
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["proposalId"]?.stringValue?.hasPrefix("ps-") == true)
        #expect(fixtures.run?.screenSuggestions == nil, "Not Suggest Screens' answer")
        let queued = try #require(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens.first)
        #expect(queued.items.map(\.name) == ["Streak widget", "Insights"])

        fixtures.center.addSuggestedScreen(queued.items[1].id, appID: MCPAutopilotFixtures.appID)
        let added = try #require(fixtures.run?.plan.screens.last)
        #expect(added.name == "Insights")
        #expect(added.steps == "tab “Insights”")
        #expect(added.origin == .suggestion(client: AutopilotTestFixtures.client))
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens.first?.items[1].status == .added)
    }

    @Test func aScreenWithoutStepsIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asked)
        await #expect(throws: (any Error).self) {
            try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": [["name": "Insights", "reason": "New"]]])
        }
        #expect(fixtures.run?.screenSuggestions == nil)
    }

    // MARK: - Outside a run

    /// Alba 1.1 gained My Phrases while its run sat at Review & Push: the
    /// screen waits for the next plan instead of being refused.
    @Test func aScreenSentAtReviewAndPushWaitsForTheNextPlan() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let outcome = try await fixtures.call(ProposeScreensTool(), [
            "screens": [
                [
                    "name": "My Phrases", "reason": "New in 1.1.", "evidence": "MyPhrasesView.swift", "steps": "tab “My Phrases”",
                    "caption": "Keep the words that move you",
                ],
            ],
        ])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["device"] == "set")
        #expect(outcome.result["count"] == 1)
        #expect(outcome.result["say"]?.stringValue?.contains("next plan") == true)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .proposed)])
        let proposals = fixtures.center.planProposals(for: MCPAutopilotFixtures.appID)
        #expect(proposals.screens.count == 1)
        #expect(proposals.screens[0].id == outcome.result["proposalId"]?.stringValue)
        #expect(proposals.screens[0].device == .iPhone)
        #expect(proposals.screens[0].items.first?.caption == "Keep the words that move you")
        #expect(fixtures.run?.plan == AutopilotTestFixtures.smallPlan, "The run's plan stays as it is")
        #expect(fixtures.run?.stage == .ready)
    }

    /// With no run at all, the screens wait too, and the plan Run
    /// Autopilot… opens takes them with Add to Plan. Start keeps the ones
    /// not added for the plan after it.
    @Test func screensSentWithoutARunAreAddedFromTheNextPlan() async throws {
        let fixtures = MCPAutopilotFixtures()
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(ProposeScreensTool(), ["screens": Self.screens])
        #expect(outcome.result["status"] == "queued")
        #expect(fixtures.run == nil)

        fixtures.center.prepare(appID: appID, versionString: "1.5", plan: AutopilotTestFixtures.smallPlan)
        let waiting = try #require(fixtures.center.planProposals(for: appID).screens.first)
        fixtures.center.addSuggestedScreen(waiting.items[0].id, appID: appID)
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens.map(\.name) == ["Today", "Week", "Streak widget"])
        #expect(plan.screens[2].caption == "Your streak, on your Home Screen")

        fixtures.center.start(appID: appID)
        let left = fixtures.center.planProposals(for: appID).screens
        #expect(left.flatMap(\.items).map(\.name) == ["Insights"], "The added one leaves; the other waits")
    }

    /// Apple Watch's own screens wait under the watch, without captions.
    @Test func watchScreensOutsideARunWaitUnderTheWatchWithoutCaptions() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.ready, everyDevice: true))
        let outcome = try await fixtures.call(ProposeScreensTool(), ["device": "watch", "screens": Self.screens])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["device"] == "watch")
        let queued = try #require(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens.first)
        #expect(queued.device == .watch)
        let captions = queued.items.map(\.caption)
        #expect(captions == ["", ""], "Watch screenshots have no captions")
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens(on: .iPhone).isEmpty)
    }

    /// A screen the plan has gets new steps through update_capture_plan,
    /// not a second copy.
    @Test func aScreenThePlanHasIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let outcome = try await fixtures.call(ProposeScreensTool(), [
            "screens": [
                ["name": "today", "reason": "The core moment.", "steps": "launch"],
                ["name": "Insights", "reason": "New in 1.4.", "steps": "tab “Insights”"],
            ],
        ])
        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [
            ["name": "today", "reason": "The plan already has “today”: send its new steps with update_capture_plan."],
        ])
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens.first?.items.map(\.name) == ["Insights"])

        let none = try await fixtures.call(ProposeScreensTool(), ["screens": [["name": "Week", "reason": "x", "steps": "y"]]])
        #expect(none.result["status"] == "refused")
        #expect(none.result["refused"]?.arrayValue?.count == 1)
    }

    @Test func appleVisionProsWindowsAreTheIPhoneScreens() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let outcome = try await fixtures.call(ProposeScreensTool(), ["device": "vision", "screens": Self.screens])
        #expect(outcome.result["status"] == "refused")
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).isEmpty)
    }

    /// Sent again, a screen still waiting is replaced, not doubled.
    @Test func aScreenSentAgainTakesThePlaceOfTheOneWaiting() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        _ = try await fixtures.call(ProposeScreensTool(), ["screens": Self.screens])
        _ = try await fixtures.call(ProposeScreensTool(), [
            "screens": [["name": "insights", "reason": "Its chart is new.", "steps": "tab “Insights” → wait for the chart"]],
        ])
        let screens = fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).screens
        #expect(screens.count == 2)
        #expect(screens.flatMap(\.items).map(\.name) == ["Streak widget", "insights"])
        #expect(screens.last?.items.first?.steps == "tab “Insights” → wait for the chart")
    }

    /// Done on the screens sent for the plan takes them away; Dismiss on one
    /// keeps it out of Add to Plan.
    @Test func doneAndDismissSettleTheScreensSentForThePlan() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.plan))
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(ProposeScreensTool(), ["screens": Self.screens])
        let waiting = try #require(fixtures.center.planProposals(for: appID).screens.first)
        fixtures.center.dismissScreenSuggestion(waiting.items[0].id, appID: appID)
        fixtures.center.addSuggestedScreen(waiting.items[0].id, appID: appID)
        #expect(fixtures.run?.plan.screens.count == 5, "A dismissed screen isn't added")
        #expect(fixtures.center.planProposals(for: appID).openScreenCount == 1)

        try fixtures.center.closeQueuedScreens(#require(outcome.result["proposalId"]?.stringValue), appID: appID)
        #expect(fixtures.center.planProposals(for: appID).isEmpty)
    }

    // MARK: - The screens the person added

    /// Waiting, with one screen added by hand (steps left to the assistant)
    /// and one from a suggestion.
    private static var withAddedScreens: AutopilotRun {
        var run = AutopilotTestFixtures.run(.waiting)
        run.plan.appendScreen(AutopilotScreen(name: "Reminders", origin: .person, worksOutSteps: true), on: .iPhone)
        run.plan.appendScreen(
            AutopilotScreen(name: "Insights", steps: "tab “Insights”", caption: "See what lifts your mood", origin: .suggestion(client: "Claude Code")),
            on: .iPhone
        )
        return run
    }

    @Test func thePlanSaysWhichScreensThePersonAddedAndWhichStepsToWorkOut() async throws {
        let fixtures = MCPAutopilotFixtures(Self.withAddedScreens)
        let result = try await fixtures.call(GetCapturePlanTool(), ["run": "run-1"]).result
        let screens = try #require(result["screens"]?.arrayValue)
        #expect(screens.count == 4)
        #expect(screens[0]["addedBy"] == nil)
        #expect(screens[2]["addedBy"] == "person")
        #expect(screens[2]["steps"] == "auto")
        #expect(screens[2]["how"]?.stringValue?.contains("add it to the UI tests") == true)
        #expect(screens[3]["addedBy"] == "suggestion")
        #expect(screens[3]["steps"] == "tab “Insights”")
        #expect(screens[3]["how"] == nil)
    }

    @Test func replacingTheScreensKeepsTheOnesThePersonAdded() async throws {
        let fixtures = MCPAutopilotFixtures(Self.withAddedScreens)
        _ = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "replace": true,
            "screens": [
                ["name": "Streaks", "steps": "tab “Streaks”", "caption": "Keep your streak going"],
                ["name": "Insights", "steps": "tab “Insights” → wait for the chart"],
            ],
        ])
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens.map(\.name) == ["Streaks", "Insights", "Reminders"])
        #expect(plan.screens[1].origin == .suggestion(client: "Claude Code"), "Sent back, it's still the suggested one")
        #expect(plan.screens[1].caption == "See what lifts your mood")
        #expect(plan.screens[2].origin == .person)
    }

    @Test func workedOutStepsReplaceAuto() async throws {
        let fixtures = MCPAutopilotFixtures(Self.withAddedScreens)
        let result = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1", "screens": [["name": "Reminders", "steps": "Settings → Reminders"]],
        ]).result
        #expect(fixtures.run?.plan.screens[2].steps == "Settings → Reminders")
        #expect(result["screens"]?.arrayValue?[2]["steps"] == "Settings → Reminders")
        #expect(result["screens"]?.arrayValue?[2]["how"] == nil)
    }
}
#endif
