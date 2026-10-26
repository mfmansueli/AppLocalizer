//
//  LocaleScopeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Which locales get their own screenshots, and what pushing them costs.
@MainActor
@Suite("Locale scope")
struct LocaleScopeTests {
    @Test func thePrimaryLocaleIsAlwaysIn() {
        var draft = LocaleScopeDraft(scope: LocaleScope(primary: "en-US", localized: ["de-DE"]))
        draft.set("en-US", included: false)
        #expect(draft.contains("en-US"))
        draft.select([])
        #expect(draft.count == 1)
        #expect(draft.contains("en-US"))
    }

    @Test func shortcutsReplaceTheSelection() {
        var draft = LocaleScopeDraft(scope: LocaleScope(primary: "en-US", localized: ["de-DE"]))
        draft.select(["fr-FR", "ja"])
        #expect(draft.localized == ["en-US", "fr-FR", "ja"])
        #expect(!draft.contains("de-DE"))
    }

    @Test func pinnedLocalesAreLeftAloneUntilUnpinned() {
        var scope = LocaleScope(primary: "en-US", localized: ["de-DE"])
        scope.pin("de-DE", at: Date(timeIntervalSince1970: 0))
        #expect(scope.isPinned("de-DE"))
        #expect(!scope.isRendered("de-DE"))
        scope.unpin("de-DE")
        #expect(scope.isRendered("de-DE"))
    }

    @Test func theEstimateCountsImagesDeletesAndSets() {
        let estimate = PushCostEstimate.scope(localeCount: 12, slotCount: 5, displayTypeCount: 2, liveImages: 80)
        #expect(estimate.images == 120)
        #expect(estimate.requests == 120 * 4 + 80 + 24)
        #expect(estimate.roundedRequests == 600)
        #expect(estimate.requestsSummary == "about 600 requests, 17% of the hourly limit")
    }

    @Test func smallEstimatesArentRounded() {
        let estimate = PushCostEstimate.scope(localeCount: 1, slotCount: 5, displayTypeCount: 2, liveImages: 0)
        #expect(estimate.requests == 42)
        #expect(estimate.roundedRequests == 42)
    }
}
