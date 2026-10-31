//
//  StudioPreview.swift
//  AppLocalizer
//

import Foundation

/// The App Store preview for one device, language and set: the product
/// header in that language, the screenshots as the store shows them, and
/// the first ones at search size.
struct StudioPreview: Hashable, Sendable {
    var name: String
    var subtitle: String?
    /// "Get", "Laden", "入手".
    var getTitle: String
    /// "4.8 ★ · 220 ratings · 4+", when it's known.
    var statsLine: String?
    var isRightToLeft: Bool
    /// What the screenshots are: iPad falls back to iPhone with no iPad set.
    var displayType: ScreenshotDisplayType
    /// "Live now · Arabic falls back to English (U.S.)".
    var note: String
    var shots: [StudioShot]
    var searchNote: String
    /// Why there are no shots, in place of the gallery: "No Apple Vision
    /// Pro screenshots yet…".
    var emptyText: String?

    /// The first three (two on iPad, one large on Apple Vision Pro, none
    /// for Apple Watch), as search results show them.
    var searchShots: [StudioShot] {
        switch displayType {
        case .iPad: Array(shots.prefix(2))
        case .visionPro: Array(shots.prefix(1))
        case .watch: []
        default: Array(shots.prefix(3))
        }
    }
}
