//
//  AccessibilityCard.swift
//  AppLocalizer
//

import Foundation

/// One family's card: what's published, the draft in App Store Connect, and
/// what's queued in Review & Push, with everything the card says about
/// them.
struct AccessibilityCard: Identifiable, Hashable, Sendable {
    var family: DeviceFamily
    var published: AccessibilityAnswer?
    /// The draft saved in App Store Connect.
    var draft: AccessibilityAnswer?
    var draftID: String?
    /// The answer waiting in Review & Push.
    var queued: AccessibilityAnswer?
    /// "Delete Draft" is waiting in Review & Push.
    var isDeletionQueued = false
    /// The family has a live version, so its label can publish.
    var isLive: Bool
    var upcomingVersion: String?

    var id: DeviceFamily { family }

    /// What the card shows: queued edits, else the draft, else what's
    /// published. A queued deletion shows what stays: the published one.
    var shown: AccessibilityAnswer? {
        if isDeletionQueued { return published }
        return queued ?? draft ?? published
    }

    var hasPendingChange: Bool { queued != nil || isDeletionQueued }

    var state: AccessibilityCardState {
        let hasDraft = (draft != nil && !isDeletionQueued) || queued != nil
        if published != nil { return hasDraft ? .publishedChangesWaiting : .published }
        if hasDraft { return isLive ? .draft : .draftCantPublish }
        return .notDeclared
    }

    /// Features that aren't on the product page yet: the pills drawn blue.
    var unpublishedFeatures: Set<AccessibilityFeature> {
        guard let shown, state != .published else { return [] }
        return shown.features.subtracting(published?.features ?? [])
    }

    /// Live now → after publishing, for a published declaration with
    /// something newer: features added and removed.
    var changesAfterPublishing: (added: [AccessibilityFeature], removed: [AccessibilityFeature])? {
        guard let published, let shown, state == .publishedChangesWaiting else { return nil }
        let added = AccessibilityFeature.allCases.filter { shown.features.contains($0) && !published.features.contains($0) }
        let removed = AccessibilityFeature.allCases.filter { !shown.features.contains($0) && published.features.contains($0) }
        return added.isEmpty && removed.isEmpty ? nil : (added, removed)
    }

    /// The card's one-line note, if it has one.
    var note: String? {
        if !isLive {
            let version = upcomingVersion ?? String(localized: "the next version")
            return String(localized: """
            No live version on \(family.name) yet. Apple only publishes labels for live devices, so this stays a draft until \
            \(version) is released.
            """)
        }
        switch state {
        case .draft: return String(localized: "Saved in App Store Connect as a draft. It isn’t on the product page.")
        case .publishedChangesWaiting where hasPendingChange:
            return String(localized: "Live on the product page as shown; the changes publish when you push them.")
        case .publishedChangesWaiting:
            return String(localized: "A newer draft is saved in App Store Connect. It isn’t on the product page yet.")
        case .notDeclared, .draftCantPublish, .published: return nil
        }
    }

    /// Delete Draft: only a draft saved in App Store Connect can be deleted.
    var canDeleteDraft: Bool { draftID != nil && !isDeletionQueued }

    /// The page column's word for it.
    var isPublished: Bool { published != nil }
}
