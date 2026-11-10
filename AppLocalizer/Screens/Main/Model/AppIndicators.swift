//
//  AppIndicators.swift
//  AppLocalizer
//

import Foundation

/// A sidebar row's indicators: unpushed changes, suggestions to review,
/// store-page locale coverage and the number of territories whose price
/// likely holds people back. Unknown values are nil and don't draw.
struct AppIndicators: Hashable, Sendable {
    var pendingChangeCount = 0
    /// Suggestions not accepted or dismissed yet, in every section: the
    /// same counts as the tab bar's badges.
    var suggestionCount = 0
    var localeCount: Int?
    /// nil for apps set to Keep my prices, apps that sell nothing, or while
    /// it's being computed.
    var priceSuggestionCount: Int?

    var hasUnpushedChanges: Bool { pendingChangeCount > 0 }
}
