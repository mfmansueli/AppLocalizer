//
//  DuoPoseToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the assistant hears about the plan's iPhone Duo row: what the
/// screenshots show and each target's pose, the closed ones first, any
/// number of screens, and no recording of the inner display while closed
/// ones are left.
@MainActor
@Suite("iPhone Duo poses over MCP")
struct DuoPoseToolsTests {
    private static func fixtures(
        screens: Int = 6, stage: AutopilotStage = .capture, _ shows: AutopilotDuoScreens = .both, _ both: AutopilotDuoBoth = .sideBySide
    ) -> MCPAutopilotFixtures {
        MCPAutopilotFixtures(AutopilotTestFixtures.run(stage, plan: AutopilotDuoRowTests.plan(screens: screens, shows, both)))
    }

    @Test func thePlanSaysWhatTheDuosScreenshotsShow() async throws {
        let outcome = try await Self.fixtures().call(GetCapturePlanTool(), ["run": "run-1"])
        let devices = try #require(outcome.result["devices"]?.arrayValue)
        let duo = try #require(devices.first { $0["displayType"] == "iphone_duo" })
        #expect(duo["poses"]?["shows"] == "both")
        #expect(duo["poses"]?["both"] == "sideBySide")
        #expect(duo["poses"]?["open"] == [1, 2, 3, 4, 5, 6])
        #expect(duo["poses"]?["closed"] == [1, 2, 3, 4, 5, 6])
        #expect(duo["poses"]?["rule"]?.stringValue?.contains("AppLocalizer puts both in one image") == true)
        #expect(duo["pixelSize"]?.stringValue?.contains("closed: 1398 × 2034 (the cover display)") == true)
    }

    @Test func theInnerDisplayAloneHasNoClosedScreens() async throws {
        let outcome = try await Self.fixtures(.inner).call(GetCapturePlanTool(), ["run": "run-1"])
        let duo = try #require(outcome.result["devices"]?.arrayValue?.first { $0["displayType"] == "iphone_duo" })
        #expect(duo["poses"]?["shows"] == "inner")
        #expect(duo["poses"]?["both"] == .null)
        #expect(duo["poses"]?["closed"] == [])
    }

    @Test func nextStepGivesTheClosedScreensFirstWithTheirPose() async throws {
        let outcome = try await Self.fixtures(screens: 3).call(NextStepTool(), ["run": "run-1"])
        #expect(outcome.result["action"] == "capture")
        let targets = try #require(outcome.result["targets"]?.arrayValue).filter { $0["displayType"] == "iphone_duo" }
        #expect(targets.count == 3)
        #expect(targets.allSatisfy { $0["pose"] == "closed" })
        #expect(outcome.result["addScreens"] == nil)
    }

    /// A problem sent without a pose is about the screens captured now:
    /// while the closed ones are left, the closed one. Alba's was filed
    /// under the open pose and its retry never ended.
    @Test func aProblemWithoutAPoseIsAboutThePoseCapturedNow() async throws {
        let fixtures = Self.fixtures(screens: 3, .both, .separate)
        let problem: [String: JSONValue] = [
            "run": "run-1", "screen": "1", "displayType": "iphone_duo", "locale": "en-US",
            "what": "iPhone Duo is open while the closed screenshots are due.", "affectsDevice": true,
        ]
        _ = try await fixtures.call(ReportCaptureProblemTool(), problem)
        #expect(fixtures.run?.problems.last?.target.duoPose == .closed)

        var open = problem
        open["pose"] = "open"
        open["screen"] = "2"
        open["affectsDevice"] = false
        _ = try await fixtures.call(ReportCaptureProblemTool(), open)
        #expect(fixtures.run?.problems.last?.target.duoPose == .open, "As sent")
        #expect(ReportCaptureProblemTool().definition.inputSchema["properties"]?["pose"] != nil)
    }

    /// The old rule wanted 6 screens on iPhone Duo; the row takes any
    /// number.
    @Test func anyNumberOfScreensIsTaken() async throws {
        let fixtures = Self.fixtures(stage: .waiting)
        let five: [JSONValue] = (1...5).map { .object(["name": .string("Pick \($0)"), "steps": "launch"]) }
        let outcome = try await fixtures.call(UpdateCapturePlanTool(), ["run": "run-1", "screens": .array(five), "replace": true])
        #expect(outcome.result["status"] == "updated")
        #expect(fixtures.run?.plan.screens.map(\.name) == (1...5).map { "Pick \($0)" })
    }

    @Test func theInnerDisplayIsntRecordedWhileClosedScreensAreLeft() async throws {
        let outcome = try await Self.fixtures().call(StartDisplayRecordingTool(), ["run": "run-1", "displayType": "iphone_duo"])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"]?.stringValue?.contains("iPhone Duo’s closed screens come first") == true)
    }
}
#endif
