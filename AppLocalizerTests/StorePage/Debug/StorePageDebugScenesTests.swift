//
//  StorePageDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// Every Store Page scene id (one per design screenshot) opens a view.
@MainActor
@Suite("StorePageDebugScenes")
struct StorePageDebugScenesTests {
    @Test(arguments: StorePageDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(StorePageDebugScenes.view(for: id) != nil)
    }

    @Test func unknownIDsAreLeftToOtherSections() {
        #expect(StorePageDebugScenes.view(for: "pricing") == nil)
    }

    @Test func idsAreUnique() {
        #expect(Set(StorePageDebugScenes.ids).count == StorePageDebugScenes.ids.count)
    }
}
#endif
