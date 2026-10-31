//
//  ListingChangeBuilderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Pending fields → Review & Push changes with their exact writes, and the
/// queue read back onto a fresh listing.
@Suite("ListingChangeBuilder")
struct ListingChangeBuilderTests {
    private let builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
    private let client = StorePageFixtures.client

    private var listing: StoreListing { StorePageContentFixtures.editable.listing() }

    private func body(_ request: PushRequest?) throws -> StorePageWriteDocument {
        try #require(StorePageWriteDocument.decode(request?.body))
    }

    @Test func nothingPendingMeansNoChanges() {
        #expect(builder.changes(for: listing).isEmpty)
    }

    @Test func clearingAFieldSendsNull() throws {
        var listing = listing
        listing.edit(.promotionalText, in: .englishUS, to: "")
        let change = try #require(builder.changes(for: listing).first)
        #expect(try body(change.requests.first).data.attributes == ["promotionalText": String?.none])
        #expect(try body(change.restoreRequests.first).attribute("promotionalText") == "Weekly Reflections are here.")
    }

    @Test func fillingAnEmptyFieldExpectsItStillEmpty() throws {
        var listing = listing
        listing.edit(.keywords, in: .german, to: "tagebuch")
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.oldValue.isEmpty)
        #expect(change.conflictCheck?.expected == nil)
        #expect(change.conflictCheck?.path == "/v1/appStoreVersionLocalizations/vl-de")
        #expect(try body(change.restoreRequests.first).data.attributes == ["keywords": String?.none])
    }

    /// A language App Store Connect has at neither level is a new App Store
    /// language: its own group, created by the change.
    @Test func aNewLocaleAtAppLevelIsPostedUnderTheAppInfo() throws {
        var listing = listing
        listing.edit(.name, in: .french, to: "Lumen : Journal")
        listing.edit(.subtitle, in: .french, to: "Notes privées")
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.id == "storePage.app1.appInfo.info.fr-FR.new")
        #expect(change.group == "Store Page · French (new)")
        #expect(change.creation?.title == "Create the French page")
        #expect(change.creation?.source == .you)
        #expect(change.creation?.fields.map(\.id) == ["name", "subtitle"])
        #expect(change.title == "French · New locale · 2 fields")
        #expect(change.requests.first?.path == "/v1/appInfoLocalizations")
        let document = try body(change.requests.first)
        #expect(document.data.type == "appInfoLocalizations")
        #expect(document.data.relationships?["appInfo"]?.data == StorePageWriteDocument.Identifier(type: "appInfos", id: "info"))
        #expect(document.attribute("name") == "Lumen : Journal")
        #expect(document.attribute("subtitle") == "Notes privées")
        #expect(change.conflictCheck == nil)
    }

    @Test func aBlockedFieldBlocksItsNewLocale() throws {
        var listing = listing
        listing.edit(.name, in: .french, to: String(repeating: "n", count: 31))
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.blockedReason?.hasPrefix("Name:") == true)
    }

    @Test func anAssistantsProposalKeepsItsSource() throws {
        var listing = listing
        listing.update(.promotionalText, in: .german) { _ = $0.propose("Neu: Wochenrückblicke", by: client) }
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.source == .assistant(client: client))
    }

    @Test func anAssistantsDifferentProposalBecomesTheAlternative() throws {
        var listing = listing
        listing.edit(.promotionalText, in: .german, to: "Meine Version")
        listing.update(.promotionalText, in: .german) { _ = $0.propose("Die Version des Assistenten", by: client) }
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.newValue == "Meine Version")
        let alternative = try #require(change.alternative)
        #expect(alternative.source == .assistant(client: client))
        #expect(alternative.newValue == "Die Version des Assistenten")
        #expect(try body(alternative.requests.first).attribute("promotionalText") == "Die Version des Assistenten")
        #expect(alternative.restoreRequests == change.restoreRequests)
    }

    @Test func ownsOnlyItsAppAndVersion() {
        var listing = listing
        listing.edit(.subtitle, in: .german, to: "Neu")
        listing.edit(.keywords, in: .german, to: "neu")
        let changes = builder.changes(for: listing)
        #expect(changes.allSatisfy(builder.owns))
        let otherVersion = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.live.ids, versionString: "1.9")
        #expect(changes.map(otherVersion.level(of:)) == [.app, nil])
        let otherApp = ListingChangeBuilder(appID: "app2", ids: StorePageContentFixtures.ids, versionString: "2.0")
        #expect(!changes.contains(where: otherApp.owns))
    }

    // MARK: - Reading the queue back

    @Test func readingTheQueueRestoresEveryKindOfChange() {
        var edited = listing
        edited.edit(.subtitle, in: .german, to: "Neu")
        edited.edit(.name, in: .french, to: "Lumen : Journal")
        edited.update(.whatsNew, in: .german) { _ = $0.propose("Neu in 2.0", by: client) }
        edited.acceptMachineTranslation("tagebuch,stimmung", for: .keywords, in: .german)

        var rebuilt = listing
        builder.apply(builder.changes(for: edited), to: &rebuilt, machineTranslated: ["de-DE.keywords": "tagebuch,stimmung"])
        #expect(rebuilt.value(.subtitle, in: .german) == "Neu")
        #expect(rebuilt.value(.name, in: .french) == "Lumen : Journal")
        #expect(rebuilt.draft(.whatsNew, in: .german).proposedBy == client)
        #expect(rebuilt.draft(.keywords, in: .german).isMachineTranslated)
        #expect(rebuilt.pendingChanges.count == edited.pendingChanges.count)
    }

    @Test func readingAnAlternativeShowsTheConflict() {
        var edited = listing
        edited.edit(.promotionalText, in: .german, to: "Meine Version")
        edited.update(.promotionalText, in: .german) { _ = $0.propose("Die Version des Assistenten", by: client) }

        var rebuilt = listing
        builder.apply(builder.changes(for: edited), to: &rebuilt)
        let draft = rebuilt.draft(.promotionalText, in: .german)
        #expect(draft.local == "Meine Version")
        #expect(draft.conflictingProposal?.value == "Die Version des Assistenten")
    }

    @Test func changesFromOtherSectionsAreIgnored() {
        var rebuilt = listing
        let foreign = PendingChange(
            id: "pricing.app1.x", appID: "app1", section: .subscriptionPricing, group: "", title: "", flagRegion: "US",
            oldValue: "", newValue: "", requests: []
        )
        builder.apply([foreign], to: &rebuilt)
        #expect(rebuilt == listing)
    }
}
