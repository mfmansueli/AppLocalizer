//
//  ListingChangeBuilderNewPageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A new App Store language as Review & Push changes: one write per level,
/// both under "Store Page · Polish (new)" and both creating the same page;
/// a language the project has is created even before it has text.
@Suite("ListingChangeBuilder new pages")
struct ListingChangeBuilderNewPageTests {
    private var builder: ListingChangeBuilder {
        var builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        builder.newPages = [.polish]
        return builder
    }

    private var listing: StoreListing { StorePageContentFixtures.editable.listing() }

    @Test func anAddedProjectLanguageIsCreatedEvenWithoutText() throws {
        var listing = listing
        listing.addLocale(.polish)
        let changes = builder.changes(for: listing)
        #expect(changes.map(\.id) == ["storePage.app1.version.v2.pl.new"])
        let change = try #require(changes.first)
        #expect(change.group == "Store Page · Polish (new)")
        #expect(change.title == "Polish · New page")
        #expect(change.source == .builtInSuggestion)
        #expect(change.newValue.isEmpty)
        let document = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(document.data.attributes == ["locale": "pl"])
        #expect(change.creation == PendingCreation(
            id: "storePage.app1.pl",
            title: "Create the Polish page",
            detail: "A new App Store language for Lumen Journal",
            source: .builtInSuggestion,
            fields: []
        ))
    }

    @Test func aLocaleAddedFromTheMenuWaitsForItsText() {
        var listing = listing
        listing.addLocale(.french)
        #expect(builder.changes(for: listing).isEmpty)
    }

    @Test func bothWritesCreateOnePageWithEveryField() throws {
        var listing = listing
        listing.edit(.name, in: .polish, to: "Lumen — Dziennik")
        listing.update(.whatsNew, in: .polish) { $0.acceptSuggestion("• Nowość", from: .assistant(client: "Claude Code")) }
        let changes = builder.changes(for: listing)
        #expect(changes.map(\.id) == ["storePage.app1.appInfo.info.pl.new", "storePage.app1.version.v2.pl.new"])
        #expect(changes.allSatisfy { $0.group == "Store Page · Polish (new)" })
        #expect(changes.allSatisfy { $0.creation?.id == "storePage.app1.pl" })
        #expect(changes.allSatisfy { $0.creation?.detail == "A new App Store language for Lumen Journal, with the text below" })
        #expect(changes[0].creation?.fields == [PendingChangePart(id: "name", title: "Name", oldValue: "", newValue: "Lumen — Dziennik", source: .you)])
        #expect(changes[1].creation?.fields.map(\.source) == [.assistant(client: "Claude Code")])

        let creation = try #require(ReviewCreation.group(changes).first)
        #expect(ReviewCreation.group(changes).count == 1)
        #expect(creation.fields.map(\.id) == ["name", "whatsNew"])
        #expect(creation.changeIDs == changes.map(\.id))
    }

    @Test func aLanguageTheAppAlreadyHasStaysUnderItsLevel() throws {
        var ids = StorePageContentFixtures.ids
        ids.appInfoLocalizations[.french] = "il-fr"
        let builder = ListingChangeBuilder(appID: "app1", ids: ids, versionString: "2.0")
        var listing = listing
        listing.edit(.whatsNew, in: .french, to: "Nouveautés")
        let change = try #require(builder.changes(for: listing).first)
        #expect(change.id == "storePage.app1.version.v2.fr-FR.new")
        #expect(change.group == "Store Page · Version 2.0")
        #expect(change.creation == nil)
    }

    @Test func aQueuedNewPageIsReadBackWithItsText() {
        var edited = listing
        edited.addLocale(.polish)
        edited.edit(.subtitle, in: .polish, to: "Dziennik nastroju")
        let changes = builder.changes(for: edited)
        #expect(ListingChangeBuilder.newLocaleCodes(in: changes, appID: "app1") == ["pl"])
        #expect(ListingChangeBuilder.newLocaleCodes(in: changes, appID: "other").isEmpty)

        var fresh = listing
        builder.apply(changes, to: &fresh)
        #expect(fresh.contains(.polish))
        #expect(fresh.value(.subtitle, in: .polish) == "Dziennik nastroju")

        // Even with no text yet, the page stays added.
        var added = listing
        added.addLocale(.polish)
        var empty = listing
        builder.apply(builder.changes(for: added), to: &empty)
        #expect(empty.contains(.polish))
    }
}
