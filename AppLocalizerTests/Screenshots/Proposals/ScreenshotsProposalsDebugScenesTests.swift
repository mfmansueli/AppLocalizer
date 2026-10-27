//
//  ScreenshotsProposalsDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Every Captures and Proposals scene id (one per design screenshot)
/// opens a view, and none is another section's.
@MainActor
@Suite("ScreenshotsProposalsDebugScenes")
struct ScreenshotsProposalsDebugScenesTests {
    @Test(arguments: ScreenshotsProposalsDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(ScreenshotsProposalsDebugScenes.view(for: id) != nil)
        #expect(ScreenshotsDebugScenes.view(for: id) == nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(ScreenshotsProposalsDebugScenes.view(for: "tpl") == nil)
    }

    @Test func idsAreUnique() {
        #expect(Set(ScreenshotsProposalsDebugScenes.ids).count == ScreenshotsProposalsDebugScenes.ids.count)
        #expect(Set(ScreenshotsProposalsDebugScenes.ids).isDisjoint(with: ScreenshotsDebugScenes.ids))
    }

    @Test func theSampleProposalsAreTheDesigns() {
        let proposals = ScreenshotsSampleData.proposals
        #expect(proposals.map(\.id) == ["p1", "p2"])
        #expect(proposals[0].template?.operations.count == 4)
        #expect(proposals[1].captions.map(\.slot) == [1, 2, 4])
        #expect(ScreenshotsSampleData.staleProposal.basedOnVersion == 3)
        #expect(ScreenshotsSampleData.staleHistory.currentNumber == 4)
    }
}
#endif
