//
//  SuggestionRunAcceptance.swift
//  AppLocalizer
//

import Foundation

/// Accept All on the Suggest Everything card: every suggestion the run
/// brought that's still open goes into its field the way the Store Page
/// and App Information accept one (tagged with who suggested it, replacing
/// what was queued there), and the toast's Undo puts the queue and the
/// decisions back. Fields that can't take a value now (locked) are
/// skipped.
@MainActor
enum SuggestionRunAcceptance {
    /// What Undo restores: each change id it touched as it was (nil when
    /// nothing was queued there), and the decisions before.
    struct Undo: Hashable, Sendable {
        var changes: [PendingChange.ID: PendingChange?] = [:]
        var review: SuggestionReviewState
    }

    /// Accepts `batch` for `appID` and returns how many went in.
    static func accept(
        _ batch: [FieldSuggestion],
        appID: StoreApp.ID,
        in workspace: MCPWorkspace,
        store: FieldSuggestionStore
    ) async -> (count: Int, undo: Undo) {
        let queue = workspace.changes
        var undo = Undo(review: store.review)
        var accepted: [(suggestion: FieldSuggestion, previous: String)] = []
        func remember(_ ids: [PendingChange.ID]) {
            for id in ids where !undo.changes.keys.contains(id) {
                undo.changes.updateValue(queue.change(id: id), forKey: id)
            }
        }

        let storePage = batch.filter { $0.target.scope.area == .storePage }
        if !storePage.isEmpty, var draft = try? await MCPListingDraft.load(app: appID, in: workspace) {
            var keys: [ListingFieldKey] = []
            for suggestion in storePage {
                guard case let .storePage(code) = suggestion.target.scope,
                      let field = ListingField(rawValue: suggestion.target.field),
                      let locale = StoreLocaleCatalog.locale(code: code),
                      draft.listing.contains(locale), draft.listing.canEdit(field) else { continue }
                accepted.append((suggestion, draft.listing.value(field, in: locale)))
                draft.accept(suggestion.value, for: field, in: locale, from: suggestion.source.changeSource)
                keys.append(ListingFieldKey(locale, field))
            }
            let ids = keys.flatMap(draft.changeIDs)
            remember(ids)
            // A value that changes hands replaces the queued one instead of
            // becoming a conflict, as on the Store Page.
            queue.discard(ids: ids)
            _ = draft.commit(to: queue)
        }

        let information = batch.filter { $0.target.scope.area == .appInformation }
        let readsAccessibility = information.contains { if case .accessibility = $0.target.scope { true } else { false } }
        if !information.isEmpty,
           var draft = try? await MCPAppInformationDraft.load(app: appID, in: workspace, includesAccessibility: readsAccessibility)
        {
            for suggestion in information {
                guard let slot = AppInformationSuggestionSlot(target: suggestion.target) else { continue }
                let previous = draft.slots.value(slot)
                guard let written = draft.slots.change(slot, to: suggestion.value, source: suggestion.source.changeSource) else { continue }
                remember([written.id])
                queue.discard(id: written.id)
                if let change = written.change { queue.upsert(change) }
                // A device's next feature builds on this one.
                draft = draft.with(changes: queue.changes(for: appID, section: .appInformation))
                accepted.append((suggestion, previous))
            }
        }

        for item in accepted {
            store.markAccepted(item.suggestion, previousValue: item.previous)
        }
        return (accepted.count, undo)
    }

    /// The toast's Undo.
    static func undo(_ undo: Undo, queue: ChangeQueue, store: FieldSuggestionStore) {
        for (id, change) in undo.changes {
            queue.discard(id: id)
            if let change { queue.upsert(change) }
        }
        store.restoreReview(undo.review)
    }
}
