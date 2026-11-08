//
//  CapturePlanReplaceToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The assistant picks the screens that show the app best: the plan says
/// it may (`chooseScreens`), and `update_capture_plan` with `replace` puts
/// its screens in place of the plan's, before the first capture, unless the
/// person keeps theirs.
@MainActor
@Suite("Autopilot tools · the assistant picks the screens")
struct CapturePlanReplaceToolsTests {
    private typealias Fixtures = AutopilotTestFixtures

    private static var everyDevice: AutopilotRun {
        var run = StudioDebugRuns.run(.waiting, everyDevice: true)
        run.captures = []
        return run
    }

    @Test func theAssistantsScreensReplaceThePlansInTheirOrder() async throws {
        let fixtures = MCPAutopilotFixtures(Fixtures.run(.waiting))
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "replace": true,
            "screens": [
                ["name": "Streaks", "steps": "tab “Streaks”", "caption": "Keep your streak going"],
                ["name": "Today", "steps": "launch → Today"],
                ["name": "Photo entry", "steps": "Today → + → Photo", "caption": "Add the photos that matter"],
            ],
        ])

        #expect(outcome.result["status"] == "updated")
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens.map(\.id) == ["streaks", "today", "photo-entry"])
        #expect(plan.screens.map(\.caption) == ["Keep your streak going", "Write a little every day", "Add the photos that matter"])
        #expect(fixtures.run?.log.last?.text == "Claude Code chose 3 screens and wrote their steps")
    }

    @Test func appleVisionProsWindowsFollowTheNewScreens() async throws {
        let fixtures = MCPAutopilotFixtures(Self.everyDevice)
        _ = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-debug",
            "replace": true,
            "screens": [["name": "Streaks", "steps": "tab “Streaks”"], ["name": "Today", "steps": "launch → Today"]],
        ])
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens(on: .visionPro).map(\.sourceScreenID) == ["streaks", "today"])
        #expect(plan.screens(on: .watch).count == 4, "Only the devices sent change")
    }

    @Test func windowsSentWithTheScreensAreKept() async throws {
        let fixtures = MCPAutopilotFixtures(Self.everyDevice)
        _ = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-debug",
            "replace": true,
            "screens": [
                ["name": "Today", "steps": "launch → Today"],
                ["name": "Week", "steps": "tab “Week”"],
                ["device": "vision", "name": "Week", "steps": "window “Week”", "sameMomentAs": "week"],
            ],
        ])
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens(on: .visionPro).map(\.id) == ["vision-week"])
        #expect(plan.screens(on: .visionPro).first?.steps == "window “Week”")
    }

    @Test func theScreensCantBeReplacedOnceCapturingHasBegun() async throws {
        var capturing = Fixtures.run(.capture)
        capturing.captures = [Fixtures.capture(Fixtures.target("today"))]
        let fixtures = MCPAutopilotFixtures(capturing)
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1", "replace": true, "screens": [["name": "Streaks", "steps": "tab “Streaks”"]],
        ])
        #expect(outcome.result == ["status": "refused", "reason": "Screens can only be replaced before the first capture."])
        #expect(fixtures.run?.plan == Fixtures.smallPlan)
    }

    @Test func thePersonCanKeepTheirScreens() async throws {
        var run = Fixtures.run(.waiting)
        run.plan.choosesScreens = false
        let fixtures = MCPAutopilotFixtures(run)
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1", "replace": true, "screens": [["name": "Streaks", "steps": "tab “Streaks”"]],
        ])
        #expect(outcome.result == ["status": "refused", "reason": "The person keeps these screens: send their steps without replace."])
        #expect(fixtures.run?.plan.screens.map(\.name) == ["Today", "Week"])
    }

    @Test func thePlanSaysWhetherTheAssistantPicks() async throws {
        let picks = try await MCPAutopilotFixtures(Fixtures.run(.waiting)).call(GetCapturePlanTool()).result
        #expect(picks["chooseScreens"] == true)

        var kept = Fixtures.run(.waiting)
        kept.plan.choosesScreens = false
        #expect(try await MCPAutopilotFixtures(kept).call(GetCapturePlanTool()).result["chooseScreens"] == false)

        var capturing = Fixtures.run(.capture)
        capturing.captures = [Fixtures.capture(Fixtures.target("today"))]
        #expect(try await MCPAutopilotFixtures(capturing).call(GetCapturePlanTool()).result["chooseScreens"] == false)
    }

    /// The captions the assistant writes when it chooses the screens are
    /// the set's headlines in every language: how to write them comes with
    /// the choice, and only then.
    @Test func choosingTheScreensSaysHowToWriteTheCaptions() async throws {
        let picks = try await MCPAutopilotFixtures(Fixtures.run(.waiting)).call(GetCapturePlanTool()).result
        let how = try #require(picks["choosingScreens"]?.stringValue)
        #expect(how.contains("search results show only the first three"))
        #expect(how.contains("not the screen's name"))
        #expect(how.contains("avoid puns and idioms"))

        var kept = Fixtures.run(.waiting)
        kept.plan.choosesScreens = false
        #expect(try await MCPAutopilotFixtures(kept).call(GetCapturePlanTool()).result["choosingScreens"] == nil)
    }

    @Test func thePromptAsksForTheBestScreens() {
        let text = MCPPrompt.runScreenshots.message(app: "Lumen Journal")["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(text.contains("When chooseScreens is true, decide first which screens show the app best"))
        #expect(text.contains("update_capture_plan replace: true"))
    }

    @Test func oldRunsLetTheAssistantPick() throws {
        let plan = Fixtures.smallPlan
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as? [String: Any])
        json.removeValue(forKey: "assistantChoosesScreens")
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.choosesScreens)
    }
}
#endif
