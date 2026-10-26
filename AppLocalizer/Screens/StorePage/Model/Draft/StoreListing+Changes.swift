//
//  StoreListing+Changes.swift
//  AppLocalizer
//

import Foundation

extension StoreListing {
    /// Every pending change, for Review & Push: locales in display order,
    /// fields in column order. Blocked ones are listed with their reason.
    var pendingChanges: [ListingChange] {
        displayLocales.flatMap { locale in
            ListingField.allCases.compactMap { field in change(for: ListingFieldKey(locale, field)) }
        }
    }

    /// The changes Push can send: pending and not blocked.
    var pushableChanges: [ListingChange] {
        pendingChanges.filter { !$0.isBlocked }
    }

    var pendingCount: Int { pendingChanges.count }

    /// The pending change for one cell, or nil if there's nothing pending.
    func change(for key: ListingFieldKey) -> ListingChange? {
        let draft = draft(key)
        guard draft.isPending || draft.hasConflict else { return nil }
        return ListingChange(
            key: key,
            oldValue: draft.remote,
            newValue: draft.local,
            source: draft.source,
            blockReason: blockReason(for: key),
            conflictingProposal: draft.conflictingProposal
        )
    }

    /// Why a pending change can't be pushed yet, if it can't.
    func blockReason(for key: ListingFieldKey) -> ListingBlockReason? {
        let draft = draft(key)
        if let proposal = draft.conflictingProposal { return .conflict(client: proposal.client) }
        switch ListingFieldValidator.validate(draft.local, for: key.field) {
        case let .overLimit(count, limit): return .overLimit(count: count, limit: limit)
        case .invalidURL: return .invalidURL
        case .valid, .empty: return nil
        }
    }
}
