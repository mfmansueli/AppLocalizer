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

    /// Adds a change, or replaces the one with the same id in place. When the
    /// person and an assistant both edit the same field to different values,
    /// both versions are kept and the review sheet asks which to push.
    func upsert(_ change: PendingChange) {
        upsert(contentsOf: [change])
    }

    func upsert(contentsOf newChanges: [PendingChange]) {
        guard !newChanges.isEmpty else { return }
        for change in newChanges {
            if let index = changes.firstIndex(where: { $0.id == change.id }) {
                changes[index] = Self.merge(changes[index], with: change)
            } else {
                changes.append(change)
            }
        }
        save()
    }

    /// The change to keep when `new` arrives for the same target as
    /// `existing`: the person's version stays primary and an assistant's
    /// different version becomes the alternative.
    private static func merge(_ existing: PendingChange, with new: PendingChange) -> PendingChange {
        let existingIsAssistant = existing.source.isAssistant
        let newIsAssistant = new.source.isAssistant
        guard existingIsAssistant != newIsAssistant, existing.newValue != new.newValue else {
            var replaced = new
            if replaced.alternative == nil, let alternative = existing.alternative, alternative.source.isAssistant != newIsAssistant {
                replaced.alternative = alternative
            }
            return replaced
        }
        var person = newIsAssistant ? existing : new
        let assistant = newIsAssistant ? new : existing
        person.alternative = ChangeAlternative(
            newValue: assistant.newValue,
            source: assistant.source,
            requests: assistant.requests,
            restoreRequests: assistant.restoreRequests
        )
        return person
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

    /// Every proposal from one assistant ("Reject All from Claude Code"):
    /// its changes go, and its versions of fields the person also edited.
    func rejectAll(fromAssistant client: String) {
        let source = ChangeSource.assistant(client: client)
        changes.removeAll { $0.source == source }
        for index in changes.indices where changes[index].alternative?.source == source {
            changes[index].alternative = nil
        }
        save()
    }

    // MARK: - Conflicts

    /// Records that App Store Connect has a different value now; the change
    /// is skipped until it's resolved.
    func markRemoteConflict(id: PendingChange.ID, _ conflict: RemoteConflict) {
        update(id) { $0.remoteConflict = conflict }
    }

    /// "Keep mine": push this value anyway, over App Store Connect's.
    func keepMine(id: PendingChange.ID) {
        update(id) { change in
            guard let conflict = change.remoteConflict else { return }
            change.conflictCheck?.expected = conflict.remoteRawValue
            change.oldValue = conflict.remoteDisplayValue
            change.remoteConflict = nil
        }
    }

    /// "Use App Store Connect's": the change is dropped.
    func useRemote(id: PendingChange.ID) {
        discard(id: id)
    }

    /// Picks the person's version or the assistant's of a field both edited.
    func resolveAlternative(id: PendingChange.ID, keepAlternative: Bool) {
        update(id) { change in
            guard let alternative = change.alternative else { return }
            if keepAlternative {
                change.newValue = alternative.newValue
                change.source = alternative.source
                change.requests = alternative.requests
                change.restoreRequests = alternative.restoreRequests
            }
            change.alternative = nil
        }
    }

    // MARK: - Options

    /// Flips a change's option (e.g. "Publish to the App Store") in review.
    /// An option that can't be turned on stays off.
    func setOption(id: PendingChange.ID, isOn: Bool) {
        update(id) { change in
            guard var option = change.option, option.isEnabled || !isOn else { return }
            option.isOn = isOn
            change.option = option
        }
    }

    private func update(_ id: PendingChange.ID, _ body: (inout PendingChange) -> Void) {
        guard let index = changes.firstIndex(where: { $0.id == id }) else { return }
        body(&changes[index])
        save()
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
