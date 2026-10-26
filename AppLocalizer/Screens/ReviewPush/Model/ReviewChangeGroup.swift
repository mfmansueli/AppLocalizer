//
//  ReviewChangeGroup.swift
//  AppLocalizer
//

import Foundation

/// One heading in the review sheet, e.g. "Subscription Pricing · Lumen Plus
/// Annual", with its schedule line and its changes in the order made.
struct ReviewChangeGroup: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var section: AppWorkspaceSection
    /// The subscription ID of a price group, for the schedule's "Edit…".
    var groupID: String?
    var note: String?
    var changes: [PendingChange]
}
