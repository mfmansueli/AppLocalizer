//
//  ChangeQueueTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ChangeQueue")
struct ChangeQueueTests {
    private func change(
        _ id: String,
        app: String = "1",
        section: AppWorkspaceSection = .storePage,
        new: String = "new",
        source: ChangeSource = .you
    ) -> PendingChange {
        PendingChange(id: id, appID: app, section: section, group: "Group", title: id, oldValue: "old", newValue: new, source: source, requests: [])
    }

    @Test func upsertAddsInOrderAndReplacesTheSameTarget() {
        let queue = ChangeQueue()
        queue.upsert(change("a"))
        queue.upsert(change("b"))
        queue.upsert(change("a", new: "newer"))
        #expect(queue.changes.map(\.id) == ["a", "b"])
        #expect(queue.change(id: "a")?.newValue == "newer")
        #expect(queue.totalCount == 2)
    }

    @Test func countsPerAppAndSection() {
        let queue = ChangeQueue(changes: [
            change("a", app: "1", section: .storePage),
            change("b", app: "1", section: .subscriptionPricing),
            change("c", app: "2"),
        ])
        #expect(queue.count(for: "1") == 2)
        #expect(queue.changes(for: "1", section: .subscriptionPricing).map(\.id) == ["b"])
        #expect(queue.hasChanges(for: "2"))
        #expect(!queue.hasChanges(for: "3"))
    }

    @Test func discardRemovesByIDAndByPredicate() {
        let queue = ChangeQueue(changes: [
            change("a"),
            change("b", source: .assistant(client: "Claude Code")),
            change("c", source: .assistant(client: "Claude Code")),
        ])
        queue.discard(id: "a")
        #expect(queue.changes.map(\.id) == ["b", "c"])
        queue.discardAll { $0.source == .assistant(client: "Claude Code") }
        #expect(queue.changes.isEmpty)
    }

    @Test func persistsEveryChangeAndLoadsItBack() {
        let url = FileManager.default.temporaryDirectory.appending(path: "ChangeQueueTests-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = FileChangeQueuePersistence(url: url)

        let queue = ChangeQueue(persistence: persistence)
        var priced = change("price.annual.BRA", section: .subscriptionPricing)
        priced.requests = [PushRequest(method: .post, path: "/v1/subscriptionPrices", body: Data("{}".utf8))]
        priced.deltaPercent = -50
        queue.upsert(priced)
        queue.upsert(change("listing.de.subtitle", source: .machineTranslation))

        let reloaded = ChangeQueue(persistence: persistence)
        #expect(reloaded.changes.map(\.id) == ["price.annual.BRA", "listing.de.subtitle"])
        #expect(reloaded.change(id: "price.annual.BRA")?.requests.first?.path == "/v1/subscriptionPrices")
        #expect(reloaded.change(id: "price.annual.BRA")?.deltaPercent == -50)
        #expect(reloaded.change(id: "listing.de.subtitle")?.source == .machineTranslation)
        #expect(reloaded.persistenceError == nil)
    }

    @Test func blockedChangesSayWhy() {
        var blocked = change("a")
        #expect(!blocked.isBlocked)
        blocked.blockedReason = "Over the limit, 31 of 30 characters"
        #expect(blocked.isBlocked)
    }
}
