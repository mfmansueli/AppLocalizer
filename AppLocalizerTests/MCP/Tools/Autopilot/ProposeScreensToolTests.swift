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
/// assistant's to work out and keep.
@MainActor
@Suite("Autopilot tools · suggest screens")
struct ProposeScreensToolTests {
    private static var asked: AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        run.screenRequest = AutopilotScreenRequest(ask: "one that shows the streak", askedAt: AutopilotTestFixtures.now)
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

    @Test func onlyAsManyAsThereIsRoomFor() async throws {
        var run = Self.asked
        for index in 6...9 { run.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["count"] == 1)
    }

    @Test func suggestionsNobodyAskedForAreRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.plan))
        let outcome = try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": Self.screens])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == "Nobody asked for screens now. The person asks with Suggest Screens in the plan.")
        #expect(fixtures.run?.screenSuggestions == nil)
    }

    @Test func aScreenWithoutStepsIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asked)
        await #expect(throws: (any Error).self) {
            try await fixtures.call(ProposeScreensTool(), ["run": "run-debug", "screens": [["name": "Insights", "reason": "New"]]])
        }
        #expect(fixtures.run?.screenSuggestions == nil)
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
