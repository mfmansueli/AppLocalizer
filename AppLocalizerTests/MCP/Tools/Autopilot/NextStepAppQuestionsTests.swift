//
//  NextStepAppQuestionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Before a run's first capture, `next_step` asks once what AppLocalizer
/// doesn't know about the app; what's known reaches the assistant in the
/// plan and the design brief.
@MainActor
@Suite("next_step · questions about the app", .serialized)
struct NextStepAppQuestionsTests {
    private static let appID = MCPAutopilotFixtures.appID
    private static let arguments: [String: JSONValue] = ["run": "run-debug"]

    /// Every question answered just now.
    private static var everythingAnswered: AppKnowledge {
        var knowledge = AppKnowledge()
        for question in AppQuestion.allCases { knowledge.set(question, text: "Known", by: nil, at: .now) }
        return knowledge
    }

    @Test func theFirstCaptureStepAsksOnce() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.capture), appSupport: AppSupportCenter())
        let first = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(first["action"] == "answer_app_questions")
        #expect(first["run"] == "run-debug")
        #expect(first["questions"]?.arrayValue?.count == AppQuestion.allCases.count)
        #expect(first["musicLibrary"]?.arrayValue?.count == AppPreviewTrack.library.count)
        #expect(fixtures.run?.appQuestionsAskedAt == AutopilotTestFixtures.now)

        let second = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(second["action"] != "answer_app_questions")
    }

    @Test func aRunWithoutAnAppPreviewAsksNoMusic() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture), appSupport: AppSupportCenter())
        fixtures.center.update(Self.appID) { $0.plan.alsoMakes = AutopilotExtras() }
        let first = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(first["action"] == "answer_app_questions")
        #expect(first["musicLibrary"] == nil)
    }

    @Test func whatsAnsweredIsntAsked() async throws {
        let support = AppSupportCenter()
        support.remember(Self.everythingAnswered, for: Self.appID)
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.capture), appSupport: support)
        let step = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(step["action"] != "answer_app_questions")
        #expect(fixtures.run?.appQuestionsAskedAt == nil)
    }

    @Test func itOnlyAsksBeforeCapturing() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.watchPreview), appSupport: AppSupportCenter())
        let step = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(step["action"] == "wait")
        #expect(fixtures.run?.appQuestionsAskedAt == nil)
    }

    @Test func withoutAPlaceToKeepThemNothingIsAsked() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.capture))
        let step = try await fixtures.call(NextStepTool(), Self.arguments).result
        #expect(step["action"] != "answer_app_questions")
    }

    /// A track picked in an earlier run plays in this one.
    @Test func aRememberedTrackApplies() async throws {
        let support = AppSupportCenter()
        var knowledge = Self.everythingAnswered
        knowledge.music = AppMusicPick(track: .lofiBeat, reason: "Relaxed")
        support.remember(knowledge, for: Self.appID)
        let fixtures = MCPAutopilotFixtures(AutopilotPreviewTestRun.run(.capture), appSupport: support)
        _ = try await fixtures.call(NextStepTool(), Self.arguments)
        #expect(fixtures.run?.plan.alsoMakes.suggestedMusic?.track == .lofiBeat)
        #expect(fixtures.run?.plan.alsoMakes.music == nil, "Still not the person's choice")
    }

    @Test func thePlanCarriesWhatsKnown() async throws {
        let support = AppSupportCenter()
        var knowledge = AppKnowledge()
        knowledge.set(.movingMoments, text: "The map pans to a new pin", by: nil, at: .now)
        support.remember(knowledge, for: Self.appID)
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.capture), appSupport: support)
        let plan = try await fixtures.call(GetCapturePlanTool(), Self.arguments).result
        #expect(plan["appKnowledge"]?["movingMoments"] == "The map pans to a new pin")
    }

    @Test func theRecordingBriefAsksForActionNotAStillScreen() {
        #expect(!AutopilotRun.recordingHow.contains("settled"))
        #expect(AutopilotRun.recordingHow.contains("makes it change"))
        #expect(AutopilotRun.recordingHow.contains("single session"))
        #expect(AutopilotRun.recordingHow.contains("press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)"))
    }
}
#endif
