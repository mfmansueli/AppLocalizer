//
//  AccessibilityRowStatus.swift
//  AppLocalizer
//

import Foundation

/// A feature row in the editor, against the published declaration.
enum AccessibilityRowStatus: Hashable, Sendable {
    /// Published and still checked.
    case live
    /// Checked, not published.
    case adds
    /// Published, now unchecked.
    case removes

    var title: String {
        switch self {
        case .live: String(localized: "Live")
        case .adds: String(localized: "Adds")
        case .removes: String(localized: "Removes")
        }
    }
}
