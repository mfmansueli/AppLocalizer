//
//  CapturePlanToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_capture_plan` and `update_capture_plan`: the run the person
/// started, picked up by the assistant, and the steps it writes from the
/// project. Also which run a tool reaches.
@MainActor
@Suite("Capture plan tools")
struct CapturePlanToolsTests {
    @Test func readingThePlanPicksTheRunUpAndGivesEverythingToCaptureWith() async throws {
        var waiting = StudioDebugRuns.run(.waiting)
        waiting.plan.simulator.extraCommands = ["xcrun simctl privacy booted grant photos dev.northpier.lumen"]
        let fixtures = MCPAutopilotFixtures(waiting)
        let outcome = try await fixtures.call(
            GetCapturePlanTool(), ["xcode": "26.1", "simulators": ["iPhone 17 Pro Max", "iPad Pro 13″"]], port: 4000
        )

        let plan = outcome.result
        #expect(plan["run"] == "run-debug")
        #expect(plan["app"] == "Lumen Journal")
        #expect(plan["version"] == "1.4")
        #expect(plan["stage"] == "capture")
        #expect(plan["primaryLocale"] == "en-US")
        #expect(plan["capturesEachLanguage"] == true)
        #expect(plan["attemptsPerScreen"] == 3)
        #expect(plan["captured"] == 0)
        #expect(plan["total"] == 120)
        #expect(plan["screens"]?.arrayValue?.first == [
            "id": "today", "slot": 1, "name": "Today", "steps": .string(StudioDebugRuns.steps[0]),
            "caption": .string(StudioDebugRuns.plan.screens[0].caption),
        ])
        #expect(plan["devices"] == [
            ["displayType": "iphone", "simulator": "iPhone 17 Pro Max", "pixelSize": "1320 × 2868", "orientation": "portrait"],
            ["displayType": "ipad", "simulator": "iPad Pro 13-inch (M5)", "pixelSize": "2752 × 2064", "orientation": "landscape"],
        ])
        let german = plan["locales"]?.arrayValue?.first { $0["locale"] == "de-DE" }
        #expect(german?["launchArguments"] == "-AppleLanguages (de-DE) -AppleLocale de_DE")
        #expect(plan["simulatorSetup"] == [
            "lightAppearance": true,
            "commands": [
                .string(AutopilotSimulatorSetup.statusBarCommand), "xcrun simctl ui booted appearance light",
                "xcrun simctl privacy booted grant photos dev.northpier.lumen",
            ],
            "sampleData": "Settings → Debug → Add Sample Week",
        ])
        #expect(plan["upload"]?["url"] == "http://127.0.0.1:4000/autopilot/debug-token")
        #expect(plan["upload"]?["how"] == "curl -s --data-binary @capture.png -H 'Content-Type: image/png' http://127.0.0.1:4000/autopilot/debug-token")
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .read)])

        let run = try #require(fixtures.run)
        #expect(run.stage == .capture)
        #expect(run.client == "Claude Code")
        #expect(run.environment == AutopilotEnvironment(xcode: "26.1", simulators: ["iPhone 17 Pro Max", "iPad Pro 13″"]))
    }

    @Test func thePlanSaysToFindTheSampleDataSwitchAndLeavesOutWhatsOff() async throws {
        var waiting = AutopilotTestFixtures.run(.waiting)
        waiting.plan.simulator.overridesStatusBar = false
        let found = try await MCPAutopilotFixtures(waiting).call(GetCapturePlanTool()).result
        #expect(found["simulatorSetup"]?["commands"] == ["xcrun simctl ui booted appearance light"])
        #expect(found["simulatorSetup"]?["sampleData"]?.stringValue?.hasPrefix("Find the app's sample-data switch") == true)

        waiting.plan.simulator.usesSampleData = false
        waiting.plan.simulator.lightAppearance = false
        waiting.plan.capturesEachLanguage = false
        let bare = try await MCPAutopilotFixtures(waiting).call(GetCapturePlanTool()).result
        #expect(bare["simulatorSetup"] == ["lightAppearance": false, "commands": []])
        #expect(bare["locales"]?.arrayValue?.count == 1)
        #expect(bare["total"] == 4)
    }

    /// Simplified and Traditional Chinese, or Brazilian and European
    /// Portuguese, are different captures: each launches in its own
    /// language, not in the bare `zh` or `pt` they share.
    @Test func eachLocaleLaunchesInItsOwnLanguage() async throws {
        var waiting = AutopilotTestFixtures.run(.waiting)
        waiting.plan.localeCodes = ["en-US", "zh-Hans", "zh-Hant", "pt-BR", "pt-PT", "es-MX", "it"]
        let plan = try await MCPAutopilotFixtures(waiting).call(GetCapturePlanTool()).result
        let arguments = try #require(plan["locales"]?.arrayValue).compactMap { $0["launchArguments"]?.stringValue }
        #expect(arguments == [
            "-AppleLanguages (en-US) -AppleLocale en_US", "-AppleLanguages (zh-Hans) -AppleLocale zh_Hans",
            "-AppleLanguages (zh-Hant) -AppleLocale zh_Hant", "-AppleLanguages (pt-BR) -AppleLocale pt_BR",
            "-AppleLanguages (pt-PT) -AppleLocale pt_PT", "-AppleLanguages (es-MX) -AppleLocale es_MX", "-AppleLanguages (it) -AppleLocale it",
        ])
    }

    // MARK: - Which run

    @Test func theToolsNeedAStartedRun() async throws {
        let message = """
        Lumen Journal has no Autopilot run waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… \
        and press Start Autopilot.
        """
        await #expect(throws: MCPToolError.notFound(message)) {
            try await MCPAutopilotFixtures().call(GetCapturePlanTool())
        }
        await #expect(throws: MCPToolError.notFound(message)) {
            try await MCPAutopilotFixtures(AutopilotTestFixtures.run(.plan)).call(ReportCaptureProblemTool())
        }
    }

    @Test func anOldRunIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture))
        let message = "Run “run-old” is over; Lumen Journal’s current run is “run-debug”. Call get_capture_plan."
        await #expect(throws: MCPToolError.notFound(message)) {
            try await fixtures.call(GetCapturePlanTool(), ["run": "run-old"])
        }
        _ = try await fixtures.call(GetCapturePlanTool(), ["run": ""])
    }

    @Test func withoutAutopilotTheToolsSaySo() async throws {
        let context = MCPToolContext(workspace: MCPAutopilotFixtures.withoutAutopilot, clientName: "Claude Code")
        let arguments = MCPToolArguments(["appId": .string(MCPAutopilotFixtures.appID)])
        await #expect(throws: MCPToolError.unavailable("Screenshot Autopilot isn’t available here.")) {
            try await GetCapturePlanTool().call(arguments, in: context)
        }
        await #expect(throws: MCPToolError.unavailable("Screenshot Autopilot isn’t available here.")) {
            try await NextStepTool().call(arguments, in: context)
        }
    }

    // MARK: - update_capture_plan

    @Test func theAssistantWritesTheStepsAndAddsScreensBeforeCapturing() async throws {
        var waiting = AutopilotTestFixtures.run(.waiting)
        waiting.plan.screens[1].caption = ""
        let fixtures = MCPAutopilotFixtures(waiting)
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "screens": [
                ["id": "today", "name": "Today", "steps": "launch -ui-sample-week", "caption": "Ignored: Today has one"],
                ["name": "WEEK", "steps": "tab “Week”", "caption": "Your week at a glance"],
                ["name": "Settings", "steps": "tab “Settings”", "caption": "Make it yours"],
            ],
            "writtenFrom": "LumenUITests/ScreenshotTests.swift",
            "sampleData": "launch argument -ui-sample-week",
        ])

        #expect(outcome.result["status"] == "updated")
        #expect(outcome.result["refused"] == nil)
        #expect(outcome.result["screens"]?.arrayValue?.count == 3)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .proposed)])
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens.map(\.id) == ["today", "week", "settings"])
        #expect(plan.screens.map(\.steps) == ["launch -ui-sample-week", "tab “Week”", "tab “Settings”"])
        #expect(plan.screens.map(\.caption) == ["Write a little every day", "Your week at a glance", "Make it yours"])
        #expect(plan.writtenFrom == "LumenUITests/ScreenshotTests.swift")
        #expect(plan.simulator.sampleDataSteps == "launch argument -ui-sample-week")
        #expect(fixtures.run?.log.last?.text == "Claude Code wrote the steps for 3 screens")
    }

    @Test func aNewScreenWithoutANameIsRefusedForThat() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.waiting))
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "screens": [["name": "  ", "steps": "tab Settings"]],
        ])

        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [["name": "", "reason": "A new screen needs a name."]])
        #expect(fixtures.run?.log.last?.date == AutopilotTestFixtures.now)
    }

    @Test func newScreensWaitForTheNextRunOnceCapturingHasBegun() async throws {
        var capturing = AutopilotTestFixtures.run(.capture)
        capturing.captures = [AutopilotTestFixtures.capture(AutopilotTestFixtures.target("today"))]
        let fixtures = MCPAutopilotFixtures(capturing)
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "screens": [["name": "Week", "steps": "tab Week"], ["name": "Settings", "steps": "tab Settings"]],
        ])

        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [["name": "Settings", "reason": "Screens can only be added before the first capture."]])
        #expect(fixtures.run?.plan.screens.map(\.steps) == ["launch → Today", "tab Week"])
    }

    @Test func thePlanCantChangeOnceCapturingIsOver() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.pick))
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), ["run": "run-1", "screens": [["name": "Today", "steps": "x"]]])
        #expect(outcome.result == ["status": "refused", "reason": "The plan can’t change now: the run is at Pick captures."])
        #expect(fixtures.run?.plan == AutopilotTestFixtures.smallPlan)
    }
}
#endif
