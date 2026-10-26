//
//  AccessibilityCardState.swift
//  AppLocalizer
//

import Foundation

/// A family card's state badge.
enum AccessibilityCardState: Hashable, Sendable {
    /// No declaration, nothing queued.
    case notDeclared
    /// Saved in App Store Connect (or queued), not on the product page.
    case draft
    /// A draft for a family with no live version: it can't publish yet.
    case draftCantPublish
    /// On the product page, nothing newer.
    case published
    /// On the product page, with a newer draft or queued edits.
    case publishedChangesWaiting

    var title: String {
        switch self {
        case .notDeclared: String(localized: "Not declared")
        case .draft: String(localized: "Draft")
        case .draftCantPublish: String(localized: "Draft · can’t publish yet")
        case .published: String(localized: "Published")
        case .publishedChangesWaiting: String(localized: "Published · changes waiting")
        }
    }
}
