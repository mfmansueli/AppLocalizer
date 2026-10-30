//
//  SuggestionsDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Board 17's DEBUG scenes resolve, and their sample suggestions are the
/// design's.
@MainActor
@Suite("SuggestionsDebugScenes")
struct SuggestionsDebugScenesTests {
    @Test(arguments: SuggestionsDebugScenes.ids)
    func everySceneResolves(_ id: String) {
        #expect(SuggestionsDebugScenes.view(for: id) != nil)
        AssistantToolbarIndicator.debugShowsPopover = false
        AssistantSetupSheet.debugStep = nil
    }

    @Test func unknownIDsAreLeftToOtherAreas() {
        #expect(SuggestionsDebugScenes.view(for: "overview") == nil)
        #expect(SuggestionsDebugScenes.view(for: "sp-unknown") == nil)
    }

    @Test func theSampleStoreHasTheAssistantsAndTheProvidersSuggestions() {
        let store = SuggestionsDebugData.store()
        let lumen = SuggestionsDebugData.appID
        #expect(store.open(for: lumen, area: .storePage).count == 5)
        #expect(store.open(for: lumen, area: .appInformation).count == 3)
        #expect(store.open(for: lumen, filter: .aiProvider).count == 1)
        #expect(SuggestionsDebugData.store(includesAssistant: false).suggestions.isEmpty)
    }

    @Test func theStreamingStoreHasTwoOfFourArrived() {
        let request = SuggestionsDebugData.streamingStore().request
        #expect(request?.received == 2)
        #expect(request?.total == 4)
    }
}
#endif
