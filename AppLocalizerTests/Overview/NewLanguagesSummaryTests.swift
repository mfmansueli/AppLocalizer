//
//  NewLanguagesSummaryTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Overview's word on the languages the app supports and its App Store
/// page doesn't: the Suggestions card names them, and the Store page card
/// counts them, or the new pages waiting to be pushed.
@MainActor
@Suite("NewLanguagesSummary")
struct NewLanguagesSummaryTests {
    private let appID = NewLanguagesFixtures.appID

    private var storePage: StorePageSummary {
        StorePageContentFixtures.editable.summary()
    }

    @Test func theSummaryKeepsTheStoreLocaleCodes() {
        #expect(storePage.localeCodes == ["en-US", "de-DE"])
        #expect(storePage.localeCount == 2)
    }

    @Test func suggestedLanguagesAreNamedAndCounted() {
        let summary = NewLanguagesSummary(appID: appID, storePage: storePage, appSupport: NewLanguagesFixtures.center(), changes: [])
        #expect(summary.pending == [.polish, .turkish, .hebrew])
        #expect(summary.suggestionText == "Polish, Turkish, Hebrew")
        #expect(summary.hasSuggestions)
        #expect(summary.languagesText == "2 · 3 more in the app")
    }

    @Test func addedOnesAreNewToPushAndDeclinedOnesAreLeftOut() {
        var builder = ListingChangeBuilder(appID: appID, ids: StorePageContentFixtures.ids, versionString: "2.0")
        builder.newPages = [.polish, .turkish, .hebrew]
        var listing = StorePageContentFixtures.editable.listing()
        listing.addLocale(.polish)
        listing.addLocale(.turkish)
        let summary = NewLanguagesSummary(
            appID: appID,
            storePage: storePage,
            appSupport: NewLanguagesFixtures.center(declined: ["he"]),
            changes: builder.changes(for: listing)
        )
        #expect(summary.addedCount == 2)
        #expect(summary.pending.isEmpty)
        #expect(summary.suggestionText == "None")
        #expect(summary.languagesText == "2 · 2 new to push")
    }

    @Test func bothAddedAndSuggested() {
        let summary = NewLanguagesSummary(storeCount: 12, pending: [.hebrew], addedCount: 2)
        #expect(summary.languagesText == "12 · 2 new to push · 1 more in the app")
    }

    @Test func nothingToSayWithoutNewLanguagesOrAnEditableVersion() {
        #expect(NewLanguagesSummary(storeCount: 12, pending: [], addedCount: 0).languagesText == nil)
        var locked = storePage
        locked.hasEditableVersion = false
        let summary = NewLanguagesSummary(appID: appID, storePage: locked, appSupport: NewLanguagesFixtures.center(), changes: [])
        #expect(summary.pending.isEmpty)
        #expect(summary.suggestionText == "None")
    }
}
