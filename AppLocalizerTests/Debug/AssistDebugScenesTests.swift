//
//  AssistDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Board 19's DEBUG scenes resolve, their key passes the canned check and
/// the short one doesn't, and the sample answers are the design's.
@MainActor
@Suite("AssistDebugScenes")
struct AssistDebugScenesTests {
    @Test(arguments: AssistDebugScenes.ids)
    func everySceneResolves(_ id: String) {
        #expect(AssistDebugScenes.view(for: id) != nil)
        AssistantToolbarIndicator.debugShowsPopover = false
        AssistantSetupSheet.debugStep = nil
        AssistantSetupSheet.debugMethod = nil
        AssistantSetupSheet.debugKey = nil
    }

    @Test func idsDontClashWithBoard17() {
        #expect(Set(AssistDebugScenes.ids).isDisjoint(with: SuggestionsDebugScenes.ids))
        #expect(AssistDebugScenes.view(for: "in-general") == nil)
    }

    @Test func theCannedServiceTakesTheKeyAndRejectsTheShortOne() async throws {
        let service = DebugKeyAssistantService(delay: .zero)
        #expect(try await service.modelIDs(vendor: .anthropic, apiKey: AssistDebugScenes.key).contains("claude-sonnet-5-5"))
        await #expect(throws: KeyAssistantKeyError.rejected(.anthropic, statusCode: 401)) {
            try await service.modelIDs(vendor: .anthropic, apiKey: AssistDebugScenes.rejectedKey)
        }
        let completion = AIProviderCompletion(system: "", user: "", model: "", maxTokens: 1, wantsJSON: true)
        let answer = try await service.complete(completion, vendor: .anthropic, apiKey: "")
        #expect(try KeyAssistantAnswerParser.items(from: answer.text, vendor: .anthropic).count == 3)
    }

    @Test func theCodeAnswersAreSixQuestionsAndFiveFeatures() {
        let store = SuggestionsDebugData.store(includesCodeAnswers: true)
        let lumen = SuggestionsDebugData.appID
        #expect(store.open(for: lumen, scope: .appInformation(.ageRating)).count == SuggestionsDebugData.ageRatingAnswers.count)
        #expect(store.open(for: lumen, scope: .accessibility(.appleWatch)).count == 4)
        #expect(store.open(for: lumen, scope: .accessibility(.iPhone)).count == 1)
        #expect(AssistDebugScenes.projectFolder.commits.count == 23)
        #expect(AssistDebugScenes.projectFolder.changelog?.title == "1.4")
    }
}
#endif
