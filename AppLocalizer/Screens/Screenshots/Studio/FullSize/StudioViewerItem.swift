//
//  StudioViewerItem.swift
//  AppLocalizer
//

import Foundation

/// One thing in the full-size viewer: its name ("2 · Week"), what else
/// says what it is (size, language), and what it draws.
struct StudioViewerItem: Hashable, Identifiable {
    var id: String
    /// "2 · Week", "Product page header · 21:9 · 3840 × 1646".
    var title: String
    /// "English (U.S.) · iPhone 6.9″ · 1320 × 2868".
    var subtitle: String
    var content: StudioViewerContent
    /// The button in the top bar, if it has one.
    var action: StudioViewerAction?
}
