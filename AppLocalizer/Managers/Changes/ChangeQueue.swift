//
//  ChangeQueue.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Every pending change across all apps, in the order they were made. The
/// sections add to it (Pricing, Store Page, App Information, assistants);
/// the toolbar shows its count and Review & Push sends and removes them.
/// Shared through the SwiftUI environment.
@MainActor
@Observable
final class ChangeQueue {
    private(set) var changes: [PendingChange] = []
    /// Set when the saved queue couldn't be read or written.
    private(set) var persistenceError: String?

    private let persistence: (any ChangeQueuePersistence)?

    init(persistence: (any ChangeQueuePersistence)? = nil, changes: [PendingChange] = []) {
        self.persistence = persistence
        self.changes = changes
        if let persistence, changes.isEmpty {
            do {
                self.changes = try persistence.load()
            } catch {
                persistenceError = error.localizedDescription
            }
        }
    }

    // MARK: - Reading

    var totalCount: Int { changes.count }

    func change(id: PendingChange.ID) -> PendingChange? {
        changes.first { $0.id == id }
    }

    func changes(for appID: StoreApp.ID) -> [PendingChange] {
        changes.filter { $0.appID == appID }
    }

    func changes(for appID: StoreApp.ID, section: AppWorkspaceSection) -> [PendingChange] {
        changes.filter { $0.appID == appID && $0.section == section }
    }

    func count(for appID: StoreApp.ID) -> Int {
        changes.count { $0.appID == appID }
    }

    func hasChanges(for appID: StoreApp.ID) -> Bool {
        changes.contains { $0.appID == appID }
    }

    // MARK: - Changing

    /// Adds a change, or replaces the one with the same id in place.
    func upsert(_ change: PendingChange) {
        upsert(contentsOf: [change])
    }

    func upsert(contentsOf newChanges: [PendingChange]) {
        guard !newChanges.isEmpty else { return }
        for change in newChanges {
            if let index = changes.firstIndex(where: { $0.id == change.id }) {
                changes[index] = change
            } else {
                changes.append(change)
            }
        }
        save()
    }

    func discard(id: PendingChange.ID) {
        discard(ids: [id])
    }

    func discard(ids: some Sequence<PendingChange.ID>) {
        let ids = Set(ids)
        guard changes.contains(where: { ids.contains($0.id) }) else { return }
        changes.removeAll { ids.contains($0.id) }
        save()
    }

    /// Discards every change matching `predicate`, e.g. all of one app's, or
    /// "Reject All" from one assistant.
    func discardAll(where predicate: (PendingChange) -> Bool) {
        let before = changes.count
        changes.removeAll(where: predicate)
        if changes.count != before { save() }
    }

    private func save() {
        guard let persistence else { return }
        do {
            try persistence.save(changes)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}
