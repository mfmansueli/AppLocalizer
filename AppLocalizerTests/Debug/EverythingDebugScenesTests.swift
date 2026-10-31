//
//  EverythingDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Board 20's DEBUG scenes resolve, and the canned run is the design's:
/// 9 of 18 while it receives, 12 when it's stopped, 18 once it finishes.
@MainActor
@Suite("EverythingDebugScenes")
struct EverythingDebugScenesTests {
    @Test(arguments: EverythingDebugScenes.ids)
    func everySceneResolves(_ id: String) {
        #expect(EverythingDebugScenes.view(for: id) != nil)
        AssistantToolbarIndicator.debugShowsPopover = false
        OverviewSectionView.debugRequestsSuggestEverything = false
        AssistantSetupSheet.debugStep = nil
        AssistantSetupSheet.debugReason = nil
    }

    @Test func idsDontClashWithTheOtherBoards() {
        #expect(Set(EverythingDebugScenes.ids).isDisjoint(with: SuggestionsDebugScenes.ids + AssistDebugScenes.ids))
    }

    @Test func theRunIsTheBoards() throws {
        let receiving = try #require(SuggestionsDebugData.runStore(arrived: 9).run)
        #expect(receiving.phase == .running)
        #expect(receiving.progressText == "Suggesting everything · 9 of 18")
        #expect(receiving.rows.map(\.progressText) == ["3 of 5", "1 of 1", "2 of 6", "2 of 5", "1 of 1"])
        #expect(receiving.rows[0].detail == "English (U.S.) 3/3 · German 0/1 · Japanese 0/1")
        #expect(receiving.rows[3].detail == "iPhone 1/1 · Apple Watch 1/4")

        let store = SuggestionsDebugData.runStore(arrived: 17)
        SuggestionsDebugData.sendNextRunItem(to: store)
        let finished = try #require(store.run)
        #expect(finished.phase == .finished)
        #expect(finished.finishedText == "Claude Code sent 18 suggestions: Store Page 5 · General 1 · Age Rating 6 · Accessibility 5 · App Review 1.")
        #expect(store.toReview(in: finished).count == 18)
    }
}
#endif
