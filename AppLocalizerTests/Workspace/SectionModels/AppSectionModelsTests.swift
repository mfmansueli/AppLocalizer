//
//  AppSectionModelsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("AppSectionModels")
struct AppSectionModelsTests {
    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_000_000)
    }

    private let clock = Clock()

    private func makeModels(maximumAge: TimeInterval = 600) -> AppSectionModels {
        AppSectionModels(maximumAge: maximumAge) { [clock] in clock.now }
    }

    @Test func everySectionNeedsItsFirstLoad() {
        let models = makeModels()
        for section in AppWorkspaceSection.allCases {
            #expect(models.needsLoad(section, refreshCount: 0))
        }
    }

    @Test func aLoadedSectionIsNotReadAgain() {
        let models = makeModels()
        models.didLoad(.storePage, refreshCount: 0)
        #expect(!models.needsLoad(.storePage, refreshCount: 0))
    }

    @Test func loadingOneSectionLeavesTheOthersToLoad() {
        let models = makeModels()
        models.didLoad(.storePage, refreshCount: 0)
        #expect(models.needsLoad(.appInformation, refreshCount: 0))
        #expect(models.needsLoad(.subscriptionPricing, refreshCount: 0))
    }

    @Test func refreshMakesEveryLoadedSectionReadAgain() {
        let models = makeModels()
        models.didLoad(.storePage, refreshCount: 0)
        models.didLoad(.screenshots, refreshCount: 0)
        #expect(models.needsLoad(.storePage, refreshCount: 1))
        #expect(models.needsLoad(.screenshots, refreshCount: 1))
    }

    /// A read that began before Refresh was asked doesn't count for it.
    @Test func aLoadStartedBeforeARefreshStaysStale() {
        let models = makeModels()
        models.didLoad(.storePage, refreshCount: 0)
        #expect(models.needsLoad(.storePage, refreshCount: 1))
        models.didLoad(.storePage, refreshCount: 1)
        #expect(!models.needsLoad(.storePage, refreshCount: 1))
    }

    @Test func anOldLoadIsReadAgain() {
        let models = makeModels(maximumAge: 600)
        models.didLoad(.appInformation, refreshCount: 0)
        clock.now += 599
        #expect(!models.needsLoad(.appInformation, refreshCount: 0))
        clock.now += 1
        #expect(models.needsLoad(.appInformation, refreshCount: 0))
    }

    @Test func loadingAgainRenewsTheAge() {
        let models = makeModels(maximumAge: 600)
        models.didLoad(.overview, refreshCount: 0)
        clock.now += 700
        models.didLoad(.overview, refreshCount: 0)
        clock.now += 500
        #expect(!models.needsLoad(.overview, refreshCount: 0))
    }
}
