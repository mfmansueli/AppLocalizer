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

    var id: PendingChange.ID { change.id }
}
