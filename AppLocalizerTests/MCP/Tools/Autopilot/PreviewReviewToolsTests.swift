//
//  PreviewReviewToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Watch the App Preview over MCP: `next_step` hands the person's change to
/// the assistant with the current cut, `revise_app_preview` sends the new
/// version, and `set_app_preview_music` picks another library track.
@MainActor
@Suite("Autopilot tools · App Preview review", .serialized)
struct PreviewReviewToolsTests {
    private static let asked = AutopilotRevisionRequest(note: "Slower pace, start with Search", askedAt: AutopilotTestFixtures.now)

    /// Watching v1 with the person's change waiting.
    private static var asking: AutopilotRun {
        var run = AutopilotPreviewTestRun.run(.watchPreview)
        run.previewReview?.request = asked
        return run
    }

    // MARK: - next_step

    @Test func nextStepHandsOverTheChangeAndTheCurrentCut() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asking)
        let result = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(result["action"] == "revise_app_preview")
        #expect(result["note"] == "Slower pace, start with Search")
        let current = try #require(result["current"])
        #expect(current["version"] == 1)
        #expect(current["screens"] == ["today", "week", "search", "photos", "privacy"])
        #expect(current["seconds"] == .double(24))
        #expect(current["captionScale"] == .double(1))
        #expect(current["endCard"] == ["caption": true, "screen": "today"])
        #expect(current["music"] == "warm_acoustic")
        #expect(result["planScreens"]?.arrayValue?.count == 5)
        #expect(result["planScreens"]?.arrayValue?.first?["name"] == "Today")
        #expect(result["musicLibrary"]?.arrayValue?.compactMap { $0["id"]?.stringValue } == ["warm_acoustic", "calm_piano", "bright_pop"])
        #expect(result["how"]?.stringValue?.contains("revise_app_preview") == true)
    }

    @Test func nextStepWaitsWhileThePersonWatchesOrAppLocalizerRemakes() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.watchPreview))
        let watching = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(watching["action"] == "wait")
        #expect(watching["reason"] == "The person is watching the App Preview.")

        var remaking = Self.asking
        remaking.previewReview?.remake = AutopilotPreviewRemake(reason: .music("Calm piano"), total: 1)
        fixtures.center.install(remaking)
        let busy = try await fixtures.call(NextStepTool(), ["run": "run-debug"]).result
        #expect(busy["action"] == "wait")
        #expect(busy["reason"] == "AppLocalizer is making the App Preview again.")
    }

    // MARK: - revise_app_preview

    @Test func aRevisionBecomesTheNextVersion() async throws {
        let fixtures = MCPAutopilotFixtures()
        try await AutopilotPreviewTestRun.watching(center: fixtures.center, services: fixtures.services) { $0.previewReview?.request = Self.asked }

        let outcome = try await fixtures.call(ReviseAppPreviewTool(), [
            "run": "run-debug", "changes": "Slower pace, starts with Search", "screens": ["search", "today", "Week"], "seconds": 28,
            "captionScale": .double(1.2), "endCard": ["caption": false], "music": "calm_piano",
        ])
        #expect(outcome.result == ["status": "revised", "version": 2, "changes": "Slower pace, starts with Search"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot · App Preview v2", outcome: .proposed)])
        let review = try #require(fixtures.run?.previewReview)
        #expect(review.cut == AppPreviewCut(
            screenIDs: ["search", "today", "week"], seconds: 28, captionScale: 1.2, endCardShowsCaption: false
        ))
        #expect(review.revisions.last?.client == AutopilotTestFixtures.client)
        #expect(fixtures.run?.plan.alsoMakes.previewMusic.track == .calmPiano)
    }

    @Test func whatIsntSentStaysAsItIs() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asking)
        let session = try await MCPAutopilotSession.load(
            MCPToolArguments(["appId": .string(MCPAutopilotFixtures.appID), "run": "run-debug"]),
            in: MCPToolContext(workspace: fixtures.workspace, clientName: AutopilotTestFixtures.client)
        )
        let current = AppPreviewCut(screenIDs: ["week", "today"], seconds: 20, captionScale: 0.9)
        let cut = try ReviseAppPreviewTool.cut(MCPToolArguments(["endCard": ["screen": "Search"]]), over: current, session: session)
        #expect(cut == AppPreviewCut(screenIDs: ["week", "today"], seconds: 20, captionScale: 0.9, endCardScreenID: "search"))
    }

    @Test func aRevisionOutsideTheRulesIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(Self.asking)
        let base: [String: JSONValue] = ["run": "run-debug", "changes": "Slower"]
        await #expect(throws: MCPToolError.invalidArgument(name: "seconds", expected: "a length from 15 to 30 seconds")) {
            try await fixtures.call(ReviseAppPreviewTool(), base.merging(["seconds": 45]) { $1 })
        }
        await #expect(throws: MCPToolError.invalidArgument(name: "captionScale", expected: "a number from 0.8 to 1.4")) {
            try await fixtures.call(ReviseAppPreviewTool(), base.merging(["captionScale": 2]) { $1 })
        }
        await #expect(throws: MCPToolError.self) {
            try await fixtures.call(ReviseAppPreviewTool(), base.merging(["screens": ["settings"]]) { $1 })
        }
        await #expect(throws: MCPToolError.self) {
            try await fixtures.call(ReviseAppPreviewTool(), base.merging(["screens": []]) { $1 })
        }
        await #expect(throws: MCPToolError.self) {
            try await fixtures.call(ReviseAppPreviewTool(), base.merging(["music": "own_file"]) { $1 })
        }
        await #expect(throws: MCPToolError.self) {
            try await fixtures.call(ReviseAppPreviewTool(), ["run": "run-debug", "changes": "  "])
        }
        #expect(fixtures.run?.previewReview?.version == 1)
        #expect(fixtures.run?.previewReview?.request == Self.asked)
    }

    @Test func aRevisionNobodyAskedForIsRefused() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.watchPreview))
        let outcome = try await fixtures.call(ReviseAppPreviewTool(), ["run": "run-debug", "changes": "Faster"])
        #expect(outcome.result == [
            "status": "refused", "reason": "No change was asked for. Call next_step to see what AppLocalizer wants.",
        ])

        fixtures.center.install(AutopilotPreviewTestRun.run(.ready))
        let late = try await fixtures.call(ReviseAppPreviewTool(), ["run": "run-debug", "changes": "Faster"])
        #expect(late.result["status"] == "refused")
    }

    // MARK: - set_app_preview_music

    @Test func theMusicIsSetAtThePlan() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.plan))
        let outcome = try await fixtures.call(SetAppPreviewMusicTool(), ["run": "run-debug", "track": "bright_pop"])
        #expect(outcome.result == ["status": "set", "track": "bright_pop"])
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot · Bright pop", outcome: .proposed)])
        #expect(fixtures.run?.plan.alsoMakes.previewMusic.track == .brightPop)
    }

    @Test func onlyALibraryTrackAtThePlanOrWhileWatching() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.plan))
        let tracks = "warm_acoustic, calm_piano, or bright_pop"
        await #expect(throws: MCPToolError.invalidArgument(name: "track", expected: "a library track: \(tracks)")) {
            try await fixtures.call(SetAppPreviewMusicTool(), ["run": "run-debug", "track": "own_file"])
        }

        fixtures.center.install(AutopilotPreviewTestRun.run(.capture))
        let capturing = try await fixtures.call(SetAppPreviewMusicTool(), ["run": "run-debug", "track": "calm_piano"])
        #expect(capturing.result["reason"] == "The music can change at the plan or at Watch the App Preview.")

        var noPreview = StudioDebugRuns.run(.plan)
        noPreview.plan.alsoMakes = AutopilotExtras()
        fixtures.center.install(noPreview)
        let none = try await fixtures.call(SetAppPreviewMusicTool(), ["run": "run-debug", "track": "calm_piano"])
        #expect(none.result["reason"] == "This run makes no App Preview.")

        fixtures.center.install(Self.asking)
        let busy = try await fixtures.call(SetAppPreviewMusicTool(), ["run": "run-debug", "track": "calm_piano"])
        #expect(busy.result["reason"] == "AppLocalizer is making the App Preview again. Try in a moment.")
        #expect(fixtures.run?.plan.alsoMakes.previewMusic == .standard)
    }
}
#endif
