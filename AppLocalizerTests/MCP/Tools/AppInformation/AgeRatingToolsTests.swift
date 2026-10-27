//
//  AgeRatingToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_age_rating` and `propose_age_rating` on Lumen's sample content:
/// seven questions unanswered in App Store Connect, answers queued as the
/// Age Rating page's changes and blocked until the person confirms them.
@MainActor
@Suite("Age rating tools")
struct AgeRatingToolsTests {
    private let services = DebugAppInformationServices()
    private let changes = ChangeQueue()
    private let lumen = "6450000001"

    private func context() -> MCPToolContext {
        MCPToolContext(workspace: MCPTestFixtures.workspace(changes: changes, appInformation: services), clientName: "Claude Code")
    }

    @Test func getAgeRatingListsQuestionsWithTheirAnswers() async throws {
        let outcome = try await GetAgeRatingTool().call(MCPToolArguments(["appId": "Lumen"]), in: context())
        let questions = try #require(outcome.result["questions"]?.arrayValue)
        #expect(questions.count == AgeRatingQuestion.allCases.count)
        let wellness = try #require(questions.first { $0["id"] == "wellness" })
        #expect(wellness["current"] == .null)
        #expect(wellness["answers"] == ["negative", "affirmative"])
        let cartoon = try #require(questions.first { $0["id"] == "cartoonViolence" })
        #expect(cartoon["current"] == "none")
        #expect(outcome.result["rating"] == "4+")
    }

    @Test func anAnswerIsQueuedUntilConfirmedWithItsEvidence() async throws {
        let outcome = try await ProposeAgeRatingTool().call(MCPToolArguments([
            "appId": "Lumen",
            "answers": [[
                "question": "wellness",
                "answer": "yes",
                "why": "Weekly reflections talk about mood.",
                "evidence": ["Lumen/Reflect/Prompts.swift:12 — mood prompts"],
            ]],
            "could_not_see": "Content on the server",
        ]), in: context())
        let result = try #require(outcome.result["results"]?.arrayValue?.first)
        #expect(result["status"] == "queued")
        let changeID = try #require(result["changeId"]?.stringValue)
        let change = try #require(changes.change(id: changeID))
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.blockedReason != nil)
        #expect(change.newValue == "Yes")
        let evidence = try #require(services.notes.notes(for: lumen).ageEvidence["wellness"])
        #expect(evidence.why == "Weekly reflections talk about mood.")
        #expect(evidence.evidence == ["Lumen/Reflect/Prompts.swift:12 — mood prompts"])
        #expect(evidence.couldNotSee == "Content on the server")
        #expect(outcome.logLines.first?.outcome == .proposed)
    }

    @Test func theSameAnswerAsAppStoreConnectIsUnchanged() async throws {
        let outcome = try await ProposeAgeRatingTool().call(MCPToolArguments([
            "appId": "Lumen",
            "answers": [["question": "violenceCartoonOrFantasy", "answer": "NONE"]],
        ]), in: context())
        #expect(outcome.result["results"]?.arrayValue?.first?["status"] == "unchanged")
        #expect(changes.changes.isEmpty)
    }

    @Test func unknownQuestionsAndAnswersAreRefused() async throws {
        let outcome = try await ProposeAgeRatingTool().call(MCPToolArguments([
            "appId": "Lumen",
            "answers": [["question": "gore", "answer": "none"], ["question": "cartoonViolence", "answer": "yes"]],
        ]), in: context())
        let results = try #require(outcome.result["results"]?.arrayValue)
        #expect(results[0]["reason"] == "Unknown question “gore”. Use an id from get_age_rating.")
        #expect(results[1]["status"] == "refused")
        #expect(results[1]["reason"]?.stringValue?.contains("none") == true)
        #expect(changes.changes.isEmpty)
    }

    @Test func answersAreReadFromTheirCommonSpellings() {
        #expect(AgeRatingAnswer.matching(true) == .affirmative)
        #expect(AgeRatingAnswer.matching("No") == .negative)
        #expect(AgeRatingAnswer.matching("INFREQUENT_OR_MILD") == .infrequent)
        #expect(AgeRatingAnswer.matching("sometimes") == nil)
        #expect(AgeRatingQuestion.matching("horrorOrFearThemes") == .horror)
    }
}
#endif
