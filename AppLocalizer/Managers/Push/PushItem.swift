//
//  PushItem.swift
//  AppLocalizer
//

import Foundation

/// One row of the push progress list: the change as it was when the push
/// started, and how far it got.
struct PushItem: Identifiable, Hashable, Sendable {
    var change: PendingChange
    var status: PushItemStatus = .queued
    /// Requests already accepted, so a retry resumes after them instead of
    /// sending them twice.
    var sentRequestCount = 0
    /// The ID App Store Connect gave a resource this change's `POST`
    /// created, for later requests that use `{createdID}`. Kept across a
    /// retry, like `sentRequestCount`.
    var createdID: String?
    /// Every resource this change's `POST`s created, by type, for later
    /// requests that use `{createdID:<type>}`. Kept across a retry.
    var createdIDs: [String: String] = [:]
    /// How far a long step of a sending change got, e.g. "Prices · 40 of
    /// 175"; nil otherwise.
    var progressNote: String?

    var id: PendingChange.ID { change.id }

    /// The change's own requests went through and its option's are being
    /// sent now, e.g. "Publishing…" after a declaration was saved.
    var isSendingOption: Bool {
        guard status == .sending, let option = change.option, option.isEffective else { return false }
        return sentRequestCount >= change.requests.count
    }
}
