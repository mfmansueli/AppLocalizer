//
//  ListingChangeBuilderStaleCreationTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A queued new locale App Store Connect has by now (added there, or
/// created along with the other level) comes back as edits of the
/// localization that's there, with its texts as the old values.
@MainActor
@Suite("ListingChangeBuilder stale creations")
struct ListingChangeBuilderStaleCreationTests {
    /// French queued as a new page while App Store Connect didn't have it.
    static var queuedFrenchPage: [PendingChange] {
        var listing = StorePageContentFixtures.editable.listing()
        listing.addLocale(.french)
        listing.edit(.name, in: .french, to: "Lumen : Journal")
        listing.edit(.description, in: .french, to: "Un journal privé.")
        listing.edit(.promotionalText, in: .french, to: "Une question chaque jour.")
        return ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0").changes(for: listing)
    }

    /// App Store Connect now: French at both levels, with the same name, an
    /// older description and no promotional text.
    static var contentWithFrench: StorePageContent {
        var ids = StorePageContentFixtures.ids
        ids.versionLocalizations[.french] = "vl-fr"
        ids.appInfoLocalizations[.french] = "il-fr"
        var content = StorePageContentFixtures.content(version: StorePageContentFixtures.editableVersion, ids: ids)
        content.locales.append(.french)
        content.texts[.french] = [.name: "Lumen : Journal", .description: "Un ancien texte."]
        return content
    }

    private func freshListing(with queue: ChangeQueue) -> (ListingChangeBuilder, StoreListing) {
        let content = Self.contentWithFrench
        let builder = ListingChangeBuilder(appID: "app1", ids: content.ids, versionString: "2.0")
        var listing = content.listing()
        builder.apply(queue.changes, to: &listing)
        return (builder, listing)
    }

    @Test func creationsOfALocaleThatIsThereNowAreStale() {
        let content = Self.contentWithFrench
        let builder = ListingChangeBuilder(appID: "app1", ids: content.ids, versionString: "2.0")
        #expect(builder.staleCreations(in: Self.queuedFrenchPage).map(\.id) == [
            "storePage.app1.appInfo.info.fr-FR.new", "storePage.app1.version.v2.fr-FR.new",
        ])
        let unchanged = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        #expect(unchanged.staleCreations(in: Self.queuedFrenchPage).isEmpty)
    }

    @Test func staleCreationsBecomeEditsOfWhatsThere() throws {
        let queued = Self.queuedFrenchPage
        let queue = ChangeQueue(changes: queued)
        let (builder, listing) = freshListing(with: queue)

        let replaced = builder.replaceStaleCreations(in: queue, listing: listing)

        #expect(replaced == ["storePage.app1.appInfo.info.fr-FR.new", "storePage.app1.version.v2.fr-FR.new"])
        // The name is there already, so only the version's texts are left.
        #expect(Set(queue.changes.map(\.id)) == [
            StorePageContentFixtures.changeID(.french, .description), StorePageContentFixtures.changeID(.french, .promotionalText),
        ])
        let description = try #require(queue.change(id: StorePageContentFixtures.changeID(.french, .description)))
        #expect(description.oldValue == "Un ancien texte.")
        #expect(description.newValue == "Un journal privé.")
        #expect(description.group == "Store Page · Version 2.0")
        #expect(description.creation == nil)
        #expect(description.requests.first?.method == .patch)
        #expect(description.requests.first?.path == "/v1/appStoreVersionLocalizations/vl-fr")
        #expect(description.conflictCheck?.expected == "Un ancien texte.")
        let creation = try #require(queued.last)
        #expect(description.createdAt == creation.createdAt)
        #expect(queue.change(id: StorePageContentFixtures.changeID(.french, .promotionalText))?.oldValue == "")
    }

    @Test func nothingChangesWhileTheLocaleIsStillMissing() {
        let queued = Self.queuedFrenchPage
        let queue = ChangeQueue(changes: queued)
        let builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        var listing = StorePageContentFixtures.editable.listing()
        builder.apply(queue.changes, to: &listing)

        #expect(builder.replaceStaleCreations(in: queue, listing: listing).isEmpty)
        #expect(queue.changes == queued)
    }
}
