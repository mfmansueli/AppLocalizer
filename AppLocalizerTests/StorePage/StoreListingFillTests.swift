//
//  StoreListingFillTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("StoreListing fill")
struct StoreListingFillTests {
    private typealias Fixtures = StorePageFixtures

    @Test func siblingCopyFillsEveryFieldAsYourEdits() throws {
        var listing = Fixtures.listing()
        let pair = try #require(StoreLocaleCatalog.siblingPairs.first { $0.target == .englishAustralia })
        let copied = listing.copy(pair)
        #expect(copied == ListingField.allCases)
        #expect(listing.contains(.englishAustralia))
        for field in ListingField.allCases {
            #expect(listing.value(field, in: .englishAustralia) == Fixtures.englishTexts[field])
            #expect(!listing.draft(field, in: .englishAustralia).isMachineTranslated)
        }
        #expect(listing.pendingChanges.allSatisfy { $0.source == .you })
    }

    @Test func siblingCopyNeverOverwrites() {
        var listing = Fixtures.listing()
        listing.edit(.name, in: .englishUK, to: "Lumen: Diary")
        let copied = listing.copy(from: .englishUS, to: .englishUK)
        #expect(copied.count == 8)
        #expect(!copied.contains(.name))
        #expect(listing.value(.name, in: .englishUK) == "Lumen: Diary")
        let copiedAgain = listing.copy(from: .englishUS, to: .englishUK)
        let copiedToItself = listing.copy(from: .englishUS, to: .englishUS)
        #expect(copiedAgain.isEmpty)
        #expect(copiedToItself.isEmpty)
    }

    @Test func readOnlyVersionsCopyOnlyAppInformation() {
        var listing = Fixtures.listing(version: Fixtures.liveVersion)
        let copied = listing.copy(from: .englishUS, to: .englishCanada)
        #expect(copied == [.name, .subtitle, .privacyPolicyURL])
    }

    @Test func copyingURLsFromThePrimaryLocale() {
        var listing = Fixtures.listing()
        let copied = listing.copyURLs(to: .german)
        #expect(copied == [.privacyPolicyURL, .supportURL, .marketingURL])
        #expect(listing.value(.supportURL, in: .german) == "https://lumen.example/support")
        #expect(listing.value(.promotionalText, in: .german).isEmpty)
        let copiedAgain = listing.copyURLs(to: .german)
        let copiedToPrimary = listing.copyURLs(to: .englishUS)
        #expect(copiedAgain.isEmpty)
        #expect(copiedToPrimary.isEmpty)
    }

    // MARK: - What's New

    @Test func whatsNewGoesToLocalesWithoutOne() {
        var listing = Fixtures.listing()
        listing.addLocale(.englishUK)
        let job = listing.whatsNewBroadcast()
        #expect(job.items.map(\.key.id) == ["de-DE.whatsNew", "en-GB.whatsNew"])
        #expect(job.items.map(\.method) == [.translate, .copy])
        #expect(job.items.allSatisfy { $0.sourceText == "Weekly Reflections and bug fixes." })
        #expect(job.summary == "2 empty fields in 2 locales.")
    }

    @Test func overwritingIncludesLocalesWithDifferentText() {
        var listing = Fixtures.listing()
        listing.addLocale(.englishUK)
        listing.edit(.whatsNew, in: .german, to: "Fehlerbehebungen.")
        listing.edit(.whatsNew, in: .englishUK, to: "Weekly Reflections and bug fixes.")
        #expect(listing.whatsNewBroadcast().isEmpty)
        #expect(listing.whatsNewBroadcast(overwriting: true).items.map(\.key.id) == ["de-DE.whatsNew"])
    }

    @Test func broadcastResultsAreMachineTranslated() {
        var listing = Fixtures.listing()
        var job = listing.whatsNewBroadcast()
        job.complete(Fixtures.key(.german, .whatsNew), with: "Wochenrückblicke und Fehlerbehebungen.")
        let applied = listing.applyTranslations(of: job)
        #expect(applied == 1)
        #expect(listing.value(.whatsNew, in: .german) == "Wochenrückblicke und Fehlerbehebungen.")
        #expect(listing.coverageState(of: .whatsNew, in: .german) == .machineTranslated)
    }
}
