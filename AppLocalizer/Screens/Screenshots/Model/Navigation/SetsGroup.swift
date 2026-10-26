//
//  SetsGroup.swift
//  AppLocalizer
//

import Foundation

/// A group of Sets rows: Localized sets, Restored · not rendered, or the
/// collapsed Use English (U.S.) screenshots.
struct SetsGroup: Identifiable, Hashable, Sendable {
    var kind: Kind
    var title: String
    var count: Int
    /// Empty while a collapsible group is collapsed.
    var rows: [SetsRow]
    var note: String?

    var id: Kind { kind }

    enum Kind: String, Hashable, Sendable {
        case localized
        case restored
        case fallback
    }
}
