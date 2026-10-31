//
//  ReviewChangeGroup.swift
//  AppLocalizer
//

import Foundation

/// One heading in the review sheet, e.g. "Subscription Pricing · Lumen Plus
/// Annual" or "Store Page · Polish (new)", with its schedule line and its
/// changes in the order made.
struct ReviewChangeGroup: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var section: AppWorkspaceSection
    /// The subscription ID of a price group, for the schedule's "Edit…".
    var groupID: String?
    var note: String?
    var changes: [PendingChange]

    /// What its changes create, one row each with their fields under it:
    /// a new App Store language. A change that needs a decision shows as
    /// its own row instead, where the decision is made.
    var creations: [ReviewCreation] {
        ReviewCreation.group(changes.filter { $0.creation != nil && !$0.needsDecision })
    }

    /// The changes shown one row each.
    var plainChanges: [PendingChange] {
        changes.filter { $0.creation == nil || $0.needsDecision }
    }

    /// The heading's count: "3 changes", or for a new language "New page ·
    /// 8 fields".
    var countText: String {
        let creations = creations
        guard !creations.isEmpty, plainChanges.isEmpty else {
            return changes.count == 1 ? String(localized: "1 change") : String(localized: "\(changes.count) changes")
        }
        let fields = creations.reduce(0) { $0 + $1.fields.count }
        let pages = creations.count == 1 ? String(localized: "New page") : String(localized: "\(creations.count) new pages")
        switch fields {
        case 0: return pages
        case 1: return String(localized: "\(pages) · 1 field")
        default: return String(localized: "\(pages) · \(fields) fields")
        }
    }
}
