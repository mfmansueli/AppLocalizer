//
//  CaptureReportToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `report_capture` and `report_capture_problem`: captures named by their
/// upload, checked against the plan and the device's size, and screens
/// that couldn't be reached.
@MainActor
@Suite("Capture report tools")
struct CaptureReportToolsTests {
    /// Reports a capture of Week on iPad in Spanish, which the sample run
    /// hasn't captured yet.
    private static let spanishWeek: [String: JSONValue] = [
        "run": "run-debug", "screen": "week", "displayType": "ipad", "locale": "es-ES", "attempt": 1, "score": .double(0.9),
        "notes": "A full week, entries every day",
    ]

    private func upload(_ file: CaptureFile, in fixtures: MCPAutopilotFixtures) throws -> String {
        let run = try #require(fixtures.run)
        return fixtures.center.registerUpload(file, for: run).id
    }

    @Test func anUploadedCaptureIsRecorded() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture))
        let id = try upload(AutopilotTestFixtures.file(.iPad, landscape: true, id: "9f2c"), in: fixtures)
        #expect(id == "up-id-1")
        var arguments = Self.spanishWeek
        arguments["upload"] = .string(id)
        let outcome = try await fixtures.call(ReportCaptureTool(), arguments)

        #expect(outcome.result == ["status": "received", "captured": 77, "total": 120, "stage": "capture"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Week · es-ES · iPad 13″", outcome: .proposed)])
        #expect(fixtures.center.uploads[id] == nil, "An upload is used once")
        let capture = try #require(fixtures.run?.captures.last)
        #expect(capture.target == AutopilotCaptureTarget(screenID: "week", displayType: .iPad, locale: "es-ES"))
        #expect(capture.captureID == "9f2c")
        #expect(capture.notes == "A full week, entries every day")
    }

    /// AppLocalizer reads the capture's text and says what to fix before
    /// the next attempt; a clean attempt then ranks first.
    @Test func aCaptureInTheWrongLanguageComesBackWithACheck() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture))
        let english = ["This week", "Five entries, mostly calm", "A long walk by the river with friends", "Dinner with Ana and her family"]
        fixtures.services.textReadings["9f2c"] = CaptureTextReading(
            lines: english.enumerated().map { RecognizedTextLine(text: $1, confidence: 0.9, top: 0.2 + Double($0) * 0.1) }, readsLanguage: true
        )
        let id = try upload(AutopilotTestFixtures.file(.iPad, landscape: true, id: "9f2c"), in: fixtures)
        var arguments = Self.spanishWeek
        arguments["upload"] = .string(id)
        let outcome = try await fixtures.call(ReportCaptureTool(), arguments)

        let issue = CaptureTextIssue.otherLanguage(found: "English", expected: "Spanish (Spain)")
        #expect(outcome.result["check"] == [["issue": .string(issue.message), "fix": .string(issue.fix)]])
        #expect(outcome.result["next"] == "Fix it and capture this screen again as attempt 2.")
        #expect(outcome.result["status"] == "received")
        #expect(fixtures.run?.captures.last?.text == CaptureTextFacts(language: "en"))
    }

    @Test func screensAreNamedByIDNameOrSlotAndLocalesByAnyCase() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        for (screen, locale) in [("today", "en-US"), ("Week", "de-de"), ("2", "EN-us")] {
            let id = try upload(AutopilotTestFixtures.file(.iPhone), in: fixtures)
            let outcome = try await fixtures.call(ReportCaptureTool(), [
                "run": "run-1", "screen": .string(screen), "displayType": "iphone", "locale": .string(locale), "upload": .string(id),
                "attempt": 1, "score": 1, "notes": "",
            ])
            #expect(outcome.result["status"] == "received", "\(screen) in \(locale)")
        }
        #expect(fixtures.run?.captures.map(\.target.screenID) == ["today", "week", "week"])
        #expect(fixtures.run?.captures.map(\.target.locale) == ["en-US", "de-DE", "en-US"])
    }

    @Test func aCaptureOutsideThePlanIsRefusedWithWhatItHas() async throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.displayTypes = [.iPhone]
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture, plan: plan))
        let base: [String: JSONValue] = ["run": "run-1", "screen": "today", "displayType": "iphone", "locale": "en-US", "upload": "up-x"]

        let cases: [([String: JSONValue], MCPToolError)] = [
            (["screen": "settings"], .invalidArgument(name: "screen", expected: "a screen ID from the plan: today, week")),
            (["displayType": "ipad"], .invalidArgument(name: "displayType", expected: "one of the plan’s devices: iphone")),
            (["locale": "th"], .invalidArgument(name: "locale", expected: "one of the plan’s locales: en-US, de-DE")),
            (["upload": "up-x"], .notFound("No upload “up-x” for this run. Upload the PNG to the plan’s upload URL first.")),
            (["upload": ""], .invalidArgument(name: "upload", expected: "the upload ID from the plan’s upload URL")),
        ]
        for (change, error) in cases {
            await #expect(throws: error) {
                try await fixtures.call(ReportCaptureTool(), base.merging(change) { $1 })
            }
        }
        #expect(fixtures.run?.captures.isEmpty == true)
    }

    @Test func anotherRunsUploadIsntThisRuns() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        var other = AutopilotTestFixtures.run(.capture)
        other.id = "run-0"
        let id = fixtures.center.registerUpload(AutopilotTestFixtures.file(.iPhone), for: other).id
        await #expect(throws: MCPToolError.notFound("No upload “\(id)” for this run. Upload the PNG to the plan’s upload URL first.")) {
            try await fixtures.call(ReportCaptureTool(), [
                "run": "run-1", "screen": "today", "displayType": "iphone", "locale": "en-US", "upload": .string(id),
            ])
        }
    }

    @Test func aFileOfTheWrongSizeIsRefusedWithTheSizeItNeeds() async throws {
        let folder = URL.temporaryDirectory.appending(path: "CaptureReportToolsTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "today.png")
        try AutopilotTestFixtures.png(width: 12, height: 26).write(to: file)
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        let arguments: [String: JSONValue] = [
            "run": "run-1", "screen": "today", "displayType": "iphone", "locale": "en-US", "file": .string(file.path(percentEncoded: false)),
        ]

        let outcome = try await fixtures.call(ReportCaptureTool(), arguments)
        #expect(outcome.result == [
            "status": "refused",
            "reason": "A 12 × 26 capture doesn’t fit iPhone 6.9″, which takes 1320 × 2868 or 2868 × 1320. Capture on iPhone 17 Pro Max.",
        ])
        #expect(outcome.logLines.first?.outcome == .refused)

        let missing = folder.appending(path: "gone.png").path(percentEncoded: false)
        let unreadable = "AppLocalizer can’t read \(missing) (it’s sandboxed). Upload the PNG to the plan’s upload URL and pass the upload ID."
        await #expect(throws: MCPToolError.unavailable(unreadable)) {
            try await fixtures.call(ReportCaptureTool(), arguments.merging(["file": .string(missing)]) { $1 })
        }
    }

    @Test func theLastCaptureMovesTheRunOnToPick() async throws {
        let last = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var start = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&start, except: [last])
        let fixtures = MCPAutopilotFixtures(start)
        let id = try upload(AutopilotTestFixtures.file(.iPad), in: fixtures)
        let outcome = try await fixtures.call(ReportCaptureTool(), [
            "run": "run-1", "screen": "week", "displayType": "ipad", "locale": "de-DE", "upload": .string(id), "attempt": 1, "score": .double(0.7), "notes": "",
        ])
        #expect(outcome.result == ["status": "received", "captured": 8, "total": 8, "stage": "pick"])
    }

    @Test func aCaptureAfterCapturingIsRefusedAndTheUploadKept() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.pick))
        let id = try upload(AutopilotTestFixtures.file(.iPhone), in: fixtures)
        let outcome = try await fixtures.call(ReportCaptureTool(), [
            "run": "run-debug", "screen": "today", "displayType": "iphone", "locale": "en-US", "upload": .string(id), "attempt": 1, "score": 1, "notes": "",
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["reason"] == "The run isn’t capturing now. Call next_step to see what AppLocalizer wants.")
        #expect(fixtures.center.uploads[id] != nil)
    }

    // MARK: - report_capture_problem

    @Test func aProblemIsReportedForThePersonToDecide() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        let outcome = try await fixtures.call(ReportCaptureProblemTool(), [
            "run": "run-1", "screen": "week", "displayType": "ipad", "locale": "de-DE",
            "what": "The photo picker asked for access.", "proposedFix": "xcrun simctl privacy booted grant photos com.northpier.lumen",
        ])

        #expect(outcome.result == [
            "status": "reported", "problem": "pr-id-1",
            "say": "The person decides in AppLocalizer. Go on with the other screens; next_step lists the retries.",
        ])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Week · de-DE · iPad 13″", outcome: .proposed)])
        let problem = try #require(fixtures.run?.openProblems.first)
        #expect(problem.target == AutopilotCaptureTarget(screenID: "week", displayType: .iPad, locale: "de-DE"))
        #expect(problem.what == "The photo picker asked for access.")
        #expect(problem.proposedFix == "xcrun simctl privacy booted grant photos com.northpier.lumen")
    }

    @Test func aRefusedCommandIsKeptWithTheProblem() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        _ = try await fixtures.call(ReportCaptureProblemTool(), [
            "run": "run-1", "screen": "week", "displayType": "iphone", "locale": "de-DE",
            "what": "xcodebuild with a variable in front was refused.",
            "proposedFix": "Add a scheme that sets LUMEN_SCREENSHOTS=1.",
            "refusedCommand": "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test -scheme Lumen",
        ])
        let problem = try #require(fixtures.run?.openProblems.first)
        #expect(problem.refusedCommand == "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test -scheme Lumen")
        #expect(problem.wasRefused)
        let description = ReportCaptureProblemTool().definition.description
        #expect(description.contains("refusedCommand"))
    }

    @Test func aChangeToTheProjectIsReportedOnceAndHoldsTheOtherLanguages() async throws {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = ["en-US", "de-DE", "ja"]
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture, plan: plan))
        let outcome = try await fixtures.call(ReportCaptureProblemTool(), [
            "run": "run-1", "screen": "week", "displayType": "iphone", "locale": "ja",
            "what": "testWeek taps app.buttons[\"Week\"], the English title.",
            "proposedFix": "Give the Week segment an accessibilityIdentifier and tap it by that.", "changesProject": true,
        ])
        let problem = try #require(fixtures.run?.openProblems.first)
        #expect(problem.changesProject == true)
        #expect(outcome.result["say"]?.stringValue?.contains("waits on this device in the other languages") == true)
        #expect(fixtures.run?.heldTargets.contains(AutopilotTestFixtures.target("week", .iPhone, "de-DE")) == true)

        let definition = ReportCaptureProblemTool().definition
        #expect(definition.description.contains("changesProject"))
        #expect(definition.inputSchema["properties"]?["changesProject"]?["type"] == "boolean")
    }

    @Test func aProblemAfterCapturingIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.design))
        let outcome = try await fixtures.call(ReportCaptureProblemTool(), [
            "run": "run-1", "screen": "today", "displayType": "iphone", "locale": "en-US", "what": "Blank screen",
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(fixtures.run?.problems.isEmpty == true)
    }
}
#endif
