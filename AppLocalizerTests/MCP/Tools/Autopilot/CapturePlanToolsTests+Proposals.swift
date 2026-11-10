//
//  CapturePlanToolsTests+Proposals.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `update_capture_plan` outside a run's capture: what it sends waits for
/// the person in the next plan, and the commands and notes fixes added are
/// replaced through it, apart, as commands only when they're xcrun or
/// xcodebuild lines.
extension CapturePlanToolsTests {
    // MARK: - Outside a capture

    /// Once capturing is over the run's plan stays as it is: the steps wait
    /// for the person in the next plan.
    @Test func onceCapturingIsOverTheStepsWaitForTheNextPlan() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.pick))
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), ["run": "run-1", "screens": [["name": "Today", "steps": "x"]]])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["waiting"] == ["steps of Today"])
        #expect(fixtures.run?.plan == AutopilotTestFixtures.smallPlan)
        let change = try #require(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).changes.first)
        #expect(change.id == outcome.result["proposalId"]?.stringValue)
        #expect(change.screens == [AutopilotScreenStepsChange(screenID: "today", name: "Today", steps: "x")])
    }

    /// Alba 1.1 at Review & Push: new steps for two screens, the sample
    /// data and the test file. Accepted in the next plan, they're its own.
    @Test func changesSentAtReviewAndPushApplyFromTheNextRunOnceAccepted() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "screens": [
                ["id": "today", "name": "Today", "steps": "launch -ui-streak → Today"],
                ["name": "week", "steps": "tab “Week” → wait for the scenes to animate"],
                ["name": "Settings", "steps": "tab “Settings”"],
            ],
            "sampleData": "launch argument -ui-sample-phrases",
            "writtenFrom": "AlbaUITests/ScreenshotTests.swift",
            "reason": "1.1 reaches Streak and the animated scenes another way.",
            "evidence": "AlbaUITests/ScreenshotTests.swift, commit 21a22e0",
        ])
        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [
            ["name": "Settings", "reason": "The plan has no screen “Settings”: suggest new screens with propose_screens."],
        ])
        #expect(outcome.result["waiting"] == ["steps of Today", "steps of Week", "sampleData", "writtenFrom"])
        #expect(outcome.result["say"]?.stringValue?.contains("applies from that run on") == true)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .proposed)])
        #expect(fixtures.run?.plan == AutopilotTestFixtures.smallPlan, "Review & Push keeps its plan")
        let change = try #require(fixtures.center.planProposals(for: appID).changes.first)
        #expect(change.reason == "1.1 reaches Streak and the animated scenes another way.")
        #expect(change.evidence == "AlbaUITests/ScreenshotTests.swift, commit 21a22e0")

        let previous = try #require(fixtures.run)
        fixtures.center.prepare(appID: appID, versionString: "1.5", plan: previous.plan)
        fixtures.center.acceptPlanChange(change.id, appID: appID)
        let plan = try #require(fixtures.run?.plan)
        #expect(plan.screens.map(\.steps) == ["launch -ui-streak → Today", "tab “Week” → wait for the scenes to animate"])
        #expect(plan.simulator.sampleDataSteps == "launch argument -ui-sample-phrases")
        #expect(plan.writtenFrom == "AlbaUITests/ScreenshotTests.swift")
        #expect(fixtures.center.planProposals(for: appID).isEmpty)
    }

    @Test func aRejectedChangeLeavesThePlanAsItIs() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.plan))
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), ["screens": [["name": "Week", "steps": "tab Week"]]])
        #expect(outcome.result["status"] == "queued", "The open plan takes it as a proposal too")
        let id = try #require(outcome.result["proposalId"]?.stringValue)
        fixtures.center.rejectPlanChange(id, appID: appID)
        #expect(fixtures.run?.plan == AutopilotTestFixtures.smallPlan)
        #expect(fixtures.center.planProposals(for: appID).isEmpty)
    }

    /// A change can only be accepted in the plan it's for: never into a
    /// run that's going.
    @Test func aChangeIsAcceptedOnlyInTheOpenPlan() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), ["sampleData": "-ui-sample"])
        try fixtures.center.acceptPlanChange(#require(outcome.result["proposalId"]?.stringValue), appID: appID)
        #expect(fixtures.run?.plan.simulator.sampleDataSteps == "")
        #expect(fixtures.center.planProposals(for: appID).changes.count == 1, "It still waits for the next plan")
    }

    @Test func nothingThatChangesThePlanIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let same = try await fixtures.call(UpdateCapturePlanTool(), ["screens": [["name": "Today", "steps": "launch → Today"]]])
        #expect(same.result["status"] == "refused")
        #expect(same.result["unchanged"] == ["Today"])
        let empty = try await fixtures.call(UpdateCapturePlanTool(), [:])
        #expect(empty.result == ["status": "refused", "reason": "Send screens, writtenFrom, sampleData, setupCommands or setupNotes."])
        let replace = try await fixtures.call(UpdateCapturePlanTool(), ["replace": true, "screens": [["name": "Today", "steps": "x"]]])
        #expect(replace.result["status"] == "refused")
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).isEmpty)
    }

    /// Without any run there's no screen to change yet, but the sample
    /// data and the setup can wait for the first plan.
    @Test func withoutARunOnlyTheSetupWaits() async throws {
        let fixtures = MCPAutopilotFixtures()
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "screens": [["name": "Today", "steps": "launch"]],
            "sampleData": "-ui-sample",
            "setupCommands": ["xcrun simctl privacy booted grant photos com.northpier.lumen"],
        ])
        #expect(outcome.result["status"] == "partial")
        #expect(outcome.result["refused"] == [["name": "Today", "reason": "Lumen Journal has no plan yet: suggest its screens with propose_screens."]])
        #expect(outcome.result["waiting"] == ["sampleData", "setupCommands"])
    }

    /// A newer change takes the place of what an older one still waits
    /// with; the rest of the older one stays.
    @Test func sendingAFieldAgainReplacesWhatWaitedForIt() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let appID = MCPAutopilotFixtures.appID
        _ = try await fixtures.call(UpdateCapturePlanTool(), ["screens": [["name": "Today", "steps": "a"]], "sampleData": "-old"])
        _ = try await fixtures.call(UpdateCapturePlanTool(), ["sampleData": "-new"])
        let changes = fixtures.center.planProposals(for: appID).changes
        #expect(changes.count == 2)
        #expect(changes[0].sampleData == nil)
        #expect(changes[0].screens.map(\.steps) == ["a"])
        #expect(changes[1].sampleData == "-new")

        _ = try await fixtures.call(UpdateCapturePlanTool(), ["screens": [["name": "Today", "steps": "b"]]])
        let latest = fixtures.center.planProposals(for: appID).changes
        #expect(latest.map(\.sampleData) == ["-new", nil], "The first one had nothing left, so it's gone")
        #expect(latest.map { $0.screens.map(\.steps) } == [[], ["b"]])
    }

    // MARK: - Commands and notes fixes added

    /// Alba's plan kept two refused `TEST_RUNNER_…=1 xcodebuild` commands
    /// and two instructions as commands: setupCommands and setupNotes
    /// replace them, accepted in the next plan.
    @Test func theCommandsAndNotesFixesAddedCanBeReplaced() async throws {
        var ready = AutopilotTestFixtures.run(.ready)
        ready.plan.simulator.extraCommands = ["xcrun simctl privacy booted grant photos com.northpier.lumen"]
        ready.plan.simulator.fixNotes = ["Install the iOS 27.1+ simulator runtime in Xcode → Settings → Components."]
        let fixtures = MCPAutopilotFixtures(ready)
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "setupCommands": [],
            "setupNotes": [],
            "reason": "The runtime is installed and the photos prompt is gone in 1.1.",
        ])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["waiting"] == ["setupCommands", "setupNotes"])
        #expect(fixtures.run?.plan.simulator.extraCommands.count == 1)

        fixtures.center.prepare(appID: appID, versionString: "1.5", plan: ready.plan)
        try fixtures.center.acceptPlanChange(#require(outcome.result["proposalId"]?.stringValue), appID: appID)
        let simulator = try #require(fixtures.run?.plan.simulator)
        #expect(simulator.extraCommands.isEmpty)
        #expect(simulator.fixNotes.isEmpty)
        #expect(simulator.notes == nil)
    }

    /// Only xcrun and xcodebuild lines are run as they are: a VAR=value in
    /// front, or an instruction, is turned away with what to do instead.
    @Test func aSetupCommandIsOneXcrunOrXcodebuildLine() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        let refusedCommand = "TEST_RUNNER_ALBA_SCREENSHOTS=1 xcodebuild test -scheme Alba"
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "setupCommands": [.string(refusedCommand), "xcodebuild test -scheme AlbaScreenshots"],
        ])
        #expect(outcome.result["status"] == "refused")
        let reason = try #require(outcome.result["reason"]?.stringValue)
        #expect(reason.contains("“\(refusedCommand)” isn’t"))
        #expect(reason.contains("setupNotes"))
        #expect(fixtures.center.planProposals(for: MCPAutopilotFixtures.appID).isEmpty)

        let instruction = try await fixtures.call(UpdateCapturePlanTool(), ["setupCommands": ["Make WatchSnapshot.preview load its phrases"]])
        #expect(instruction.result["status"] == "refused")
        #expect(AutopilotSimulatorSetup.isSetupCommand("xcrun simctl io booted screenshot today.png"))
        #expect(!AutopilotSimulatorSetup.isSetupCommand("defaults write com.apple.iphonesimulator ShowChrome -bool NO"))
        #expect(!AutopilotSimulatorSetup.isSetupCommand("xcrun simctl boot A\nxcrun simctl boot B"))
    }

    /// While a run captures, its steps are written right away, but the
    /// commands the person took from fixes still wait for them.
    @Test func duringACaptureTheStepsAreWrittenAndTheCommandsWait() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.waiting))
        let appID = MCPAutopilotFixtures.appID
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), [
            "run": "run-1",
            "screens": [["name": "Today", "steps": "launch -ui-sample-week"]],
            "setupCommands": ["xcrun simctl privacy booted grant photos com.northpier.lumen"],
        ])
        #expect(outcome.result["status"] == "updated")
        #expect(outcome.result["setup"]?["status"] == "queued")
        #expect(fixtures.run?.plan.screens.first?.steps == "launch -ui-sample-week")
        #expect(fixtures.run?.plan.simulator.extraCommands.isEmpty == true)
        let change = try #require(fixtures.center.planProposals(for: appID).changes.first)
        #expect(change.id == outcome.result["setup"]?["proposalId"]?.stringValue)
        #expect(change.setupCommands == ["xcrun simctl privacy booted grant photos com.northpier.lumen"])
        #expect(change.screens.isEmpty)

        let onlySetup = try await fixtures.call(UpdateCapturePlanTool(), ["run": "run-1", "setupNotes": ["Answer the photos prompt first."]])
        #expect(onlySetup.result["status"] == "queued")
        #expect(onlySetup.result["waiting"] == ["setupNotes"])
    }

    /// Runs from before kept every fix as a command, instructions too:
    /// read back, those are notes, which get_capture_plan lists apart and
    /// never as commands to run.
    @Test func oldFixesThatArentCommandsAreReadBackAsNotes() async throws {
        let saved = Data("""
        {"overridesStatusBar":true,"usesSampleData":true,"sampleDataSteps":"","lightAppearance":true,"extraCommands":[
        "xcrun simctl privacy booted grant photos com.lima.alba",
        "TEST_RUNNER_ALBA_SCREENSHOTS=1 xcodebuild test -scheme Alba -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'",
        "Make WatchSnapshot.preview load its phrases from the localized phrases_<lang>.json, then run -scheme AlbaWatch",
        "Install the iOS 27.1+ simulator runtime"]}
        """.utf8)
        let setup = try JSONDecoder().decode(AutopilotSimulatorSetup.self, from: saved)
        #expect(setup.extraCommands == ["xcrun simctl privacy booted grant photos com.lima.alba"])
        #expect(setup.fixNotes.count == 3)
        #expect(setup.fixNotes.first?.hasPrefix("TEST_RUNNER_ALBA_SCREENSHOTS=1") == true)
        #expect(setup.grantsPermissions && setup.sampleDataInEachLanguage, "What it didn't say keeps its default")
        let again = try JSONDecoder().decode(AutopilotSimulatorSetup.self, from: JSONEncoder().encode(setup))
        #expect(again == setup)

        var waiting = AutopilotTestFixtures.run(.waiting)
        waiting.plan.simulator = setup
        let plan = try await MCPAutopilotFixtures(waiting).call(GetCapturePlanTool()).result
        let commands = (plan["simulatorSetup"]?["commands"]?.arrayValue ?? []).compactMap(\.stringValue)
        #expect(!commands.contains { $0.hasPrefix("TEST_RUNNER") || $0.hasPrefix("Install") })
        #expect(plan["simulatorSetup"]?["addedByFixes"] == ["xcrun simctl privacy booted grant photos com.lima.alba"])
        #expect(plan["simulatorSetup"]?["notes"]?.arrayValue?.count == 3)
        #expect(plan["simulatorSetup"]?["notesAre"] == .string(AutopilotSimulatorSetup.notesNote))
    }

    /// Retry with Fix: an xcrun or xcodebuild line joins the commands;
    /// another program's line is a note, never run as it is.
    @Test func aFixJoinsTheCommandsOnlyWhenItsXcrunOrXcodebuild() {
        var setup = AutopilotSimulatorSetup()
        setup.addFix("  xcrun simctl privacy booted grant photos com.northpier.lumen ")
        setup.addFix("xcrun simctl privacy booted grant photos com.northpier.lumen")
        setup.addFix("defaults write com.apple.iphonesimulator ShowChrome -bool NO")
        setup.addFix("")
        #expect(setup.extraCommands == ["xcrun simctl privacy booted grant photos com.northpier.lumen"])
        #expect(setup.fixNotes == ["defaults write com.apple.iphonesimulator ShowChrome -bool NO"])
    }

    /// The assistant sees what already waits for the next plan, so it
    /// doesn't send it again.
    @Test func thePlanSaysWhatWaitsForTheNextPlan() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready))
        _ = try await fixtures.call(UpdateCapturePlanTool(), ["screens": [["name": "Week", "steps": "tab Week"]]])
        _ = try await fixtures.call(ProposeScreensTool(), [
            "screens": [["name": "My Phrases", "reason": "New in 1.1.", "steps": "tab “My Phrases”"]],
        ])
        let plan = try await fixtures.call(GetCapturePlanTool()).result
        let queued = try #require(plan["queuedForNextPlan"]?.arrayValue)
        #expect(queued.count == 2)
        #expect(queued[0]["kind"] == "changes")
        #expect(queued[0]["waiting"] == ["steps of Week"])
        #expect(queued[1]["kind"] == "screens")
        #expect(queued[1]["device"] == "set")
        #expect(queued[1]["screens"] == ["My Phrases"])

        let bare = try await MCPAutopilotFixtures(AutopilotTestFixtures.run(.ready)).call(GetCapturePlanTool()).result
        #expect(bare["queuedForNextPlan"] == nil)
    }
}
#endif
