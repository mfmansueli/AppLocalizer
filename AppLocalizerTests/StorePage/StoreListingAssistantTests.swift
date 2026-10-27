//
//  StoreListingAssistantTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("StoreListing assistant proposals")
struct StoreListingAssistantTests {
    private typealias Fixtures = StorePageFixtures
    private let client = StorePageFixtures.client

    @Test func proposalsAreQueuedAndAttributed() {
        var listing = Fixtures.listing()
        let outcome = listing.propose("Lumen schützt deine Notizen.", for: .promotionalText, localeCode: "de-DE", by: client)
        #expect(outcome == .queued)
        let change = listing.change(for: Fixtures.key(.german, .promotionalText))
        #expect(change?.source == .assistant(client: client))
        #expect(change?.isBlocked == false)
        #expect(listing.coverageState(of: .promotionalText, in: .german) == .proposed(client: client))
    }

    @Test func aProposalOnYourChangeBlocksThePush() {
        var listing = Fixtures.listing()
        listing.edit(.subtitle, in: .german, to: "Private Notizen")
        let outcome = listing.propose("Notizen, sanft gefragt", for: .subtitle, in: .german, by: client)
        #expect(outcome == .conflict)
        let change = listing.change(for: Fixtures.key(.german, .subtitle))
        #expect(change?.blockReason == .conflict(client: client))
        #expect(change?.blockReason?.message == "You and Claude Code both changed this field. Pick the one to push.")
        #expect(change?.conflictingProposal?.value == "Notizen, sanft gefragt")
        #expect(listing.pushableChanges.isEmpty)

        listing.resolveConflict(Fixtures.key(.german, .subtitle), keeping: .assistant)
        #expect(listing.value(.subtitle, in: .german) == "Notizen, sanft gefragt")
        #expect(listing.pushableChanges.count == 1)
    }

    @Test func unknownLocalesAreRefused() {
        var listing = Fixtures.listing()
        let outcome = listing.propose("Olá", for: .name, localeCode: "pt", by: client)
        #expect(outcome == .refused(.unknownLocale("pt")))
        #expect(outcome.status == "refused")
        #expect(ListingProposalRefusal.unknownLocale("pt").reason == "“pt” isn’t an App Store locale.")
    }

    @Test func localesTheAppDoesntHaveAreRefused() {
        var listing = Fixtures.listing()
        let outcome = listing.propose("루멘", for: .name, in: .korean, by: client)
        #expect(outcome == .refused(.localeNotInListing(.korean)))
        #expect(!listing.contains(.korean))
        #expect(
            ListingProposalRefusal.localeNotInListing(.korean).reason
                == "Korean isn’t one of this app’s locales yet. Ask the person to add it in AppLocalizer."
        )
    }

    @Test func readOnlyVersionsRefuseVersionFields() {
        var listing = Fixtures.listing(version: Fixtures.liveVersion)
        let description = listing.propose("Neu", for: .description, in: .german, by: client)
        #expect(description == .refused(.notEditable(version: "1.9")))
        let name = listing.propose("Lumen", for: .name, in: .german, by: client)
        #expect(name == .queued)
    }

    @Test func invalidValuesAreRefused() {
        var listing = Fixtures.listing()
        let subtitle = listing.propose("Private Notizen, sanfte Impulse", for: .subtitle, in: .german, by: client)
        #expect(subtitle == .refused(.overLimit(count: 31, limit: ListingTextLimit(30))))
        #expect(ListingProposalRefusal.overLimit(count: 31, limit: ListingTextLimit(30)).reason == "Over the limit: 31 of 30 characters.")
        let url = listing.propose("lumen.example/de", for: .marketingURL, in: .german, by: client)
        #expect(url == .refused(.invalidURL))
        #expect(listing.pendingChanges.isEmpty)
    }

    @Test func sameValueIsUnchanged() {
        var listing = Fixtures.listing()
        let outcome = listing.propose("Lumen: Tagebuch", for: .name, in: .german, by: client)
        #expect(outcome == .unchanged)
        #expect(outcome.status == "queued")
    }

    @Test func discardingAClientsProposals() {
        var listing = Fixtures.listing()
        _ = listing.propose("Lumen schützt deine Notizen.", for: .promotionalText, in: .german, by: client)
        _ = listing.propose("Weekly Reflections, now in Lumen.", for: .promotionalText, in: .englishUS, by: client)
        listing.edit(.subtitle, in: .german, to: "Private Notizen")
        _ = listing.propose("Notizen, sanft gefragt", for: .subtitle, in: .german, by: client)
        listing.edit(.name, in: .german, to: "Lumen")

        let otherCount = listing.discardProposals(from: "Other Client")
        let ownCount = listing.discardProposals(from: client)
        #expect(otherCount == 0)
        #expect(ownCount == 3)
        #expect(listing.pendingChanges.map(\.key.id) == ["de-DE.name", "de-DE.subtitle"])
        #expect(listing.pushableChanges.count == 2)
    }
}
