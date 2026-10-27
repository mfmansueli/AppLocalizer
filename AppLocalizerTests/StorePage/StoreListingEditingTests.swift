//
//  StoreListingEditingTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("StoreListing editing")
struct StoreListingEditingTests {
    private typealias Fixtures = StorePageFixtures

    // MARK: - Sample data

    @Test func fetchedListingHasNothingPending() {
        let listing = StorePageSampleData.fetchedListing
        #expect(listing.pendingChanges.isEmpty)
        #expect(listing.locales == StorePageSampleData.presentLocales)
        #expect(listing.addableLocales.count == 29)
    }

    @Test func displayOrderIsPrimaryThenByName() {
        #expect(StorePageSampleData.listing.displayLocales.map(\.code) == [
            "en-US", "ar-SA", "en-GB", "fr-FR", "de-DE", "it", "ja", "pt-BR", "es-MX", "es-ES",
        ])
    }

    @Test func theSampleHasTwoChangesAndOneIsBlocked() throws {
        let listing = StorePageSampleData.listing
        #expect(listing.pendingChanges.map(\.key.id) == ["fr-FR.promotionalText", "de-DE.subtitle"])
        #expect(listing.pushableChanges.map(\.key.id) == ["fr-FR.promotionalText"])
        #expect(listing.pendingCount == 2)

        let subtitle = try #require(listing.change(for: ListingFieldKey(.german, .subtitle)))
        #expect(subtitle.title == "German · Subtitle")
        #expect(subtitle.oldValue == "Private Notizen, sanfte Fragen")
        #expect(subtitle.newValue == "Private Notizen, sanfte Impulse")
        #expect(subtitle.source == .you)
        #expect(subtitle.blockReason == .overLimit(count: 31, limit: ListingTextLimit(30)))
        #expect(subtitle.blockReason?.message == "Over the limit · fix it in Store Page")
    }

    // MARK: - Editing

    @Test func editingQueuesAChangeAndRevertingRemovesIt() {
        var listing = Fixtures.listing()
        listing.edit(.subtitle, in: .german, to: "Private Notizen")
        #expect(listing.pendingChanges.map(\.key.id) == ["de-DE.subtitle"])
        listing.edit(.subtitle, in: .german, to: "Private Notizen, sanfte Fragen")
        #expect(listing.pendingChanges.isEmpty)
    }

    @Test func invalidURLsAreBlocked() {
        var listing = Fixtures.listing()
        listing.edit(.supportURL, in: .german, to: "lumen.example/de/support")
        let change = listing.change(for: Fixtures.key(.german, .supportURL))
        #expect(change?.blockReason == .invalidURL)
        #expect(change?.blockReason?.message == "Not a valid https URL")
        #expect(listing.pushableChanges.isEmpty)
    }

    @Test func discardingOneOrAll() {
        var listing = StorePageSampleData.listing
        listing.discard(ListingFieldKey(.german, .subtitle))
        #expect(listing.value(.subtitle, in: .german) == "Private Notizen, sanfte Fragen")
        #expect(listing.pendingCount == 1)
        listing.discardAll()
        #expect(listing.pendingChanges.isEmpty)
        #expect(listing == StorePageSampleData.fetchedListing)
    }

    @Test func pushedChangesStopBeingPending() {
        var listing = StorePageSampleData.listing
        listing.markPushed(listing.pushableChanges.map(\.key))
        #expect(listing.pendingChanges.map(\.key.id) == ["de-DE.subtitle"])
        #expect(listing.draft(.promotionalText, in: .french).remote.hasPrefix("Nouveau : vos bilans"))
    }

    @Test func machineTranslatedURLsArentTagged() {
        var listing = Fixtures.listing()
        listing.acceptMachineTranslation("Lumen schützt deine Notizen.", for: .promotionalText, in: .german)
        listing.acceptMachineTranslation("https://lumen.example/de/support", for: .supportURL, in: .german)
        #expect(listing.draft(.promotionalText, in: .german).isMachineTranslated)
        #expect(!listing.draft(.supportURL, in: .german).isMachineTranslated)
        #expect(listing.change(for: Fixtures.key(.german, .promotionalText))?.source == .machineTranslation)
        #expect(listing.change(for: Fixtures.key(.german, .supportURL))?.source == .you)
    }

    @Test func reviewingALocaleDropsEveryTag() {
        var listing = StorePageSampleData.fetchedListing
        #expect(listing.draft(.keywords, in: .japanese).isMachineTranslated)
        listing.markReviewed(.japanese)
        #expect(!listing.draft(.keywords, in: .japanese).isMachineTranslated)
        #expect(listing.pendingChanges.isEmpty)
    }

    @Test func remoteUpdatesKeepYourChanges() {
        var listing = Fixtures.listing()
        listing.edit(.name, in: .german, to: "Lumen")
        listing.updateRemote("Lumen: Mein Tagebuch", for: .name, in: .german)
        listing.updateRemote("Lumen: Diario", for: .name, in: .italian)
        #expect(listing.value(.name, in: .german) == "Lumen")
        #expect(listing.draft(.name, in: .german).remote == "Lumen: Mein Tagebuch")
        #expect(listing.contains(.italian))
        #expect(listing.value(.name, in: .italian) == "Lumen: Diario")
    }

    // MARK: - Versions

    @Test func readOnlyVersionsOnlyEditAppInformation() {
        var listing = Fixtures.listing(version: Fixtures.liveVersion)
        #expect(listing.canEdit(.name))
        #expect(listing.canEdit(.privacyPolicyURL))
        #expect(!listing.canEdit(.description))
        listing.edit(.description, in: .german, to: "Neu")
        listing.edit(.name, in: .german, to: "Lumen")
        #expect(listing.value(.description, in: .german) == "Lumen hält deine Notizen privat.")
        #expect(listing.pendingChanges.map(\.key.id) == ["de-DE.name"])
    }

    @Test func firstVersionsHaveNoWhatsNew() {
        var listing = Fixtures.listing(version: Fixtures.firstVersion)
        #expect(!listing.fields.contains(.whatsNew))
        #expect(listing.fields.count == 8)
        listing.edit(.whatsNew, in: .german, to: "Neu")
        #expect(listing.pendingChanges.isEmpty)
    }

    // MARK: - Locales

    @Test func addingALocale() {
        var listing = Fixtures.listing()
        listing.addLocale(.korean)
        listing.addLocale(.korean)
        #expect(listing.locales == [.englishUS, .german, .korean])
        #expect(listing.displayLocales == [.englishUS, .german, .korean])
        #expect(listing.localeListing(.korean)?.isEmpty == true)
        #expect(!listing.addableLocales.contains(.korean))
    }

    @Test func onlyNewLocalesCanBeRemoved() {
        var listing = Fixtures.listing()
        listing.edit(.name, in: .korean, to: "루멘")
        let removedPrimary = listing.removeLocale(.englishUS)
        let removedFetched = listing.removeLocale(.german)
        let removedNew = listing.removeLocale(.korean)
        #expect(!removedPrimary)
        #expect(!removedFetched)
        #expect(removedNew)
        #expect(!listing.contains(.korean))
        #expect(listing.pendingChanges.isEmpty)
    }

    @Test func primaryLocaleIsAlwaysPresent() {
        let listing = StoreListing(appName: "Empty", version: Fixtures.editableVersion, primaryLocale: .german, locales: [])
        #expect(listing.locales == [.german])
        #expect(listing.value(.name, in: .german).isEmpty)
        #expect(listing.validation(of: .name, in: .german) == .empty)
    }
}
