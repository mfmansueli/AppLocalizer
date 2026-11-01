//
//  ListingChangeBuilder+StaleCreations.swift
//  AppLocalizer
//

import Foundation

extension ListingChangeBuilder {
    /// Queued `POST`s for a locale App Store Connect has at that level by
    /// now (added there after the change was queued, or created along with
    /// the other level's localization): sending one would be refused as a
    /// duplicate.
    func staleCreations(in changes: [PendingChange]) -> [PendingChange] {
        changes.filter { change in
            guard change.id.hasSuffix(".\(Self.newLocaleSuffix)"),
                  let level = level(of: change),
                  let code = StorePageWriteDocument.decode(change.requests.first?.body)?.attribute("locale"),
                  let locale = StoreLocaleCatalog.locale(code: code)
            else { return false }
            return ids.localizationID(for: locale, at: level) != nil
        }
    }

    /// Rewrites the queue's stale creations as edits of the localizations
    /// that are there. `listing` is App Store Connect's texts with the queue
    /// laid on, so each field comes back with what's there as its old
    /// value and a conflict check, and one that already has the text drops
    /// out. Returns the IDs it replaced.
    @MainActor
    @discardableResult
    func replaceStaleCreations(in queue: ChangeQueue, listing: StoreListing) -> [PendingChange.ID] {
        let queued = queue.changes(for: appID, section: .storePage)
        let stale = staleCreations(in: queued)
        guard !stale.isEmpty else { return [] }
        let queuedIDs = Set(queued.map(\.id))
        let desired = changes(for: listing)
        let edits = stale.flatMap { creation in
            // `….<locale>.new` → the locale's field changes, `….<locale>.<field>`.
            let prefix = String(creation.id.dropLast(Self.newLocaleSuffix.count))
            return desired
                .filter { $0.id.hasPrefix(prefix) && !queuedIDs.contains($0.id) }
                .map { edit in
                    var edit = edit
                    edit.createdAt = creation.createdAt
                    return edit
                }
        }
        queue.discard(ids: stale.map(\.id))
        queue.upsert(contentsOf: edits)
        return stale.map(\.id)
    }
}
