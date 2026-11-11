//
//  WorkspaceSectionModelsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("WorkspaceSectionModels")
struct WorkspaceSectionModelsTests {
    @Test func theSameAppGetsTheSameModels() {
        let store = WorkspaceSectionModels()
        let first = store.models(for: "1")
        first.didLoad(.storePage, refreshCount: 0)
        #expect(store.models(for: "1") === first)
        #expect(!store.models(for: "1").needsLoad(.storePage, refreshCount: 0))
    }

    @Test func eachAppHasItsOwnModels() {
        let store = WorkspaceSectionModels()
        store.models(for: "1").didLoad(.storePage, refreshCount: 0)
        #expect(store.models(for: "2") !== store.models(for: "1"))
        #expect(store.models(for: "2").needsLoad(.storePage, refreshCount: 0))
    }

    @Test func theAppOpenedLongestAgoIsDroppedPastTheLimit() {
        let store = WorkspaceSectionModels(appLimit: 2)
        let first = store.models(for: "1")
        _ = store.models(for: "2")
        _ = store.models(for: "3")
        #expect(store.keptAppIDs == ["2", "3"])
        #expect(store.models(for: "1") !== first)
    }

    @Test func openingAnAppAgainKeepsItOverOlderOnes() {
        let store = WorkspaceSectionModels(appLimit: 2)
        let first = store.models(for: "1")
        _ = store.models(for: "2")
        _ = store.models(for: "1")
        _ = store.models(for: "3")
        #expect(store.keptAppIDs == ["1", "3"])
        #expect(store.models(for: "1") === first)
    }

    @Test func aLimitBelowOneStillKeepsTheOpenApp() {
        let store = WorkspaceSectionModels(appLimit: 0)
        let first = store.models(for: "1")
        #expect(store.models(for: "1") === first)
    }

    @Test func theClockAndAgeReachEachAppsModels() {
        var now = Date(timeIntervalSince1970: 1_000_000)
        let store = WorkspaceSectionModels(maximumAge: 60) { now }
        store.models(for: "1").didLoad(.screenshots, refreshCount: 0)
        now += 61
        #expect(store.models(for: "1").needsLoad(.screenshots, refreshCount: 0))
    }
}
