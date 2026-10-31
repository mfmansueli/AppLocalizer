//
//  ReviewCreationTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// "Create the Polish page" in Review & Push: its writes show as one row
/// with every field under it, the heading counts the page and its fields,
/// and checking or discarding it does all of its writes.
@MainActor
@Suite("ReviewCreation")
struct ReviewCreationTests {
    private let queue = ChangeQueue()

    /// Polish added with a name, a subtitle and What's New: two writes.
    private var polishChanges: [PendingChange] {
        var builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        builder.newPages = [.polish]
        var listing = StorePageContentFixtures.editable.listing()
        listing.edit(.whatsNew, in: .polish, to: "• Nowość")
        listing.edit(.subtitle, in: .polish, to: "Dziennik nastroju")
        listing.update(.name, in: .polish) { $0.acceptSuggestion("Lumen — Dziennik", from: .assistant(client: "Claude Code")) }
        return builder.changes(for: listing)
    }

    private func makeViewModel() -> ReviewPushViewModel {
        let push = PushController(queue: queue, history: PushHistory(), transport: FakePushTransport())
        return ReviewPushViewModel(queue: queue, push: push, selectedAppID: "app1", appName: { _ in "Lumen Journal" })
    }

    @Test func aNewPagesWritesAreOneRowWithItsFieldsInTheEditorsOrder() throws {
        let creations = ReviewCreation.group(polishChanges)
        let creation = try #require(creations.first)
        #expect(creations.count == 1)
        #expect(creation.title == "Create the Polish page")
        #expect(creation.detail == "A new App Store language for Lumen Journal, with the text below")
        #expect(creation.source == .builtInSuggestion)
        #expect(creation.flagRegion == "PL")
        #expect(creation.fields.map(\.title) == ["Name", "Subtitle", "What’s New"])
        #expect(creation.fields.map(\.source) == [.assistant(client: "Claude Code"), .you, .you])
        #expect(!creation.isBlocked)
    }

    @Test func theHeadingCountsThePageAndItsFields() throws {
        queue.upsert(contentsOf: polishChanges)
        let viewModel = makeViewModel()
        let group = try #require(viewModel.appGroups.first?.groups.first)
        #expect(group.title == "Store Page · Polish (new)")
        #expect(group.creations.count == 1)
        #expect(group.plainChanges.isEmpty)
        #expect(group.countText == "New page · 3 fields")
    }

    @Test func checkingThePageChecksEveryWrite() throws {
        queue.upsert(contentsOf: polishChanges)
        let viewModel = makeViewModel()
        let creation = try #require(viewModel.appGroups.first?.groups.first?.creations.first)
        #expect(!viewModel.isSelected(creation))
        viewModel.toggle(creation)
        #expect(viewModel.selection == Set(creation.changeIDs))
        #expect(viewModel.isSelected(creation))
        viewModel.toggle(creation)
        #expect(viewModel.selection.isEmpty)
    }

    @Test func discardingThePageDiscardsEveryWrite() throws {
        queue.upsert(contentsOf: polishChanges)
        queue.upsert(PushFixtures.price("BRA"))
        let viewModel = makeViewModel()
        let creation = try #require(viewModel.appGroups.flatMap(\.groups).flatMap(\.creations).first)
        viewModel.toggle(creation)
        viewModel.discard(creation)
        #expect(queue.changes.map(\.id) == [PushFixtures.price("BRA").id])
        #expect(viewModel.selection.isEmpty)
    }

    @Test func aFieldOverTheLimitBlocksThePage() throws {
        var builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        builder.newPages = [.polish]
        var listing = StorePageContentFixtures.editable.listing()
        listing.edit(.name, in: .polish, to: String(repeating: "n", count: 31))
        let creation = try #require(ReviewCreation.group(builder.changes(for: listing)).first)
        #expect(creation.isBlocked)
        #expect(creation.blockingMessage?.hasPrefix("Name:") == true)

        queue.upsert(contentsOf: builder.changes(for: listing))
        let viewModel = makeViewModel()
        viewModel.toggle(creation)
        #expect(!viewModel.isSelected(creation))
    }

    @Test func aPlainGroupStillCountsChanges() {
        let group = ReviewChangeGroup(id: "g", title: "Store Page · Version 2.0", section: .storePage, groupID: nil, note: nil, changes: [
            PushFixtures.listing("Subtitle"), PushFixtures.listing("Keywords"),
        ])
        #expect(group.countText == "2 changes")
        #expect(group.creations.isEmpty)
    }
}
