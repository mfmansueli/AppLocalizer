//
//  AnswerAppQuestionsToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `answer_app_questions`: what the assistant found out about the app is
/// kept for later runs, and the track it picks plays unless the person
/// chose one.
@MainActor
@Suite("answer_app_questions")
struct AnswerAppQuestionsToolTests {
    private static let appID = MCPAutopilotFixtures.appID

    private let support = AppSupportCenter()

    private func fixtures(_ run: AutopilotRun? = AutopilotPreviewTestRun.run(.capture)) -> MCPAutopilotFixtures {
        MCPAutopilotFixtures(run, appSupport: support)
    }

    @Test func theAnswersAreKept() async throws {
        let outcome = try await fixtures().call(AnswerAppQuestionsTool(), [
            "answers": [
                ["question": "soundMood", "answer": "Quiet, for the evening"],
                ["question": "voice", "answer": "Plain and kind"],
            ],
        ])
        #expect(outcome.result["status"] == "saved")
        let knowledge = try #require(support.knowledge(for: Self.appID))
        #expect(knowledge.answer(to: .soundMood) == "Quiet, for the evening")
        #expect(knowledge.answers["voice"]?.answeredBy == AutopilotTestFixtures.client)
        let due = outcome.result["stillDue"]?.arrayValue?.compactMap(\.stringValue) ?? []
        #expect(due.count == AppQuestion.allCases.count - 2)
        #expect(!due.contains("soundMood"))
    }

    @Test func whatTheProjectDoesntSayIsntAskedAgain() async throws {
        _ = try await fixtures().call(AnswerAppQuestionsTool(), ["answers": [["question": "offLimits"]]])
        let knowledge = try #require(support.knowledge(for: Self.appID))
        #expect(knowledge.answer(to: .offLimits) == nil)
        #expect(!knowledge.due(now: .now).contains(.offLimits))
    }

    @Test func anUnknownQuestionIsSaidBack() async throws {
        let outcome = try await fixtures().call(AnswerAppQuestionsTool(), [
            "answers": [["question": "favouriteColour", "answer": "Blue"], ["question": "voice", "answer": "Plain"]],
        ])
        #expect(outcome.result["unknownQuestions"] == ["favouriteColour"])
    }

    @Test func thePickedTrackPlaysUnlessThePersonChose() async throws {
        let fixtures = fixtures()
        let outcome = try await fixtures.call(AnswerAppQuestionsTool(), ["music_track": "soft_ambient", "music_reason": "People use it alone at night"])
        #expect(outcome.result["musicApplied"] == true)
        #expect(fixtures.run?.plan.alsoMakes.previewMusic.track == .softAmbient)
        #expect(support.knowledge(for: Self.appID)?.music?.reason == "People use it alone at night")

        fixtures.center.update(Self.appID) { $0.plan.alsoMakes.music = AutopilotPreviewMusic(track: .calmPiano) }
        let chosen = try await fixtures.call(AnswerAppQuestionsTool(), ["music_track": "lofi_beat"])
        #expect(chosen.result["musicApplied"] == false)
        #expect(fixtures.run?.plan.alsoMakes.previewMusic.track == .calmPiano)
        #expect(support.knowledge(for: Self.appID)?.music?.track == .lofiBeat, "Kept for later runs")
    }

    @Test func onlyALibraryTrack() async throws {
        await #expect(throws: MCPToolError.self) {
            _ = try await fixtures().call(AnswerAppQuestionsTool(), ["music_track": "own_file"])
        }
        await #expect(throws: MCPToolError.self) {
            _ = try await fixtures().call(AnswerAppQuestionsTool(), ["music_track": "dubstep"])
        }
        #expect(support.knowledge(for: Self.appID) == nil)
    }

    @Test func nothingToKeepIsAMistake() async throws {
        await #expect(throws: MCPToolError.self) {
            _ = try await fixtures().call(AnswerAppQuestionsTool(), [:])
        }
    }

    @Test func theToolIsServedAndChangesState() {
        let definition = MCPToolbox.standard.tool(named: "answer_app_questions")?.definition
        #expect(definition?.isReadOnly == false)
    }
}
#endif
