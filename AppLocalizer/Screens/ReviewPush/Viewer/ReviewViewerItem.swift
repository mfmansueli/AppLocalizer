//
//  ReviewViewerItem.swift
//  AppLocalizer
//

import Foundation

/// One thing in Review & Push's viewer: its name ("German · iPhone ·
/// 2 Week"), what else says what it is, and what it draws. A screenshot
/// says something else for its live side.
struct ReviewViewerItem: Hashable, Identifiable {
    var id: String
    /// "German · iPhone · 2 Week", "German · Header 21:9".
    var title: String
    /// "New · replaces what’s live · 1320 × 2868".
    var subtitle: String
    /// A screenshot's live side: "Live now on App Store Connect · 1320 ×
    /// 2868", or what shows there without one ("Nothing live here: the
    /// push adds it"). Nil for the extras, which have one side.
    var liveSubtitle: String?
    var content: ReviewViewerContent

    /// Whether it has a live side to switch to.
    var comparesSides: Bool { liveSubtitle != nil }

    /// What `side` says.
    func subtitle(_ side: ReviewViewerSide) -> String {
        side == .live ? liveSubtitle ?? subtitle : subtitle
    }
}
