//
//  AutopilotArtworkMotion.swift
//  AppLocalizer
//

import Foundation

/// The header and search artwork as a still image or a motion loop. Apple
/// takes motion only at 21:9 and 3:2: .mov, .m4v or .mp4, 30 or 60 fps,
/// 5–30 s, played on repeat and muted.
enum AutopilotArtworkMotion: String, Codable, CaseIterable, Hashable, Sendable {
    /// One PNG per place and language.
    case still
    /// A 20-second silent loop per place and language, its first frame
    /// the poster.
    case loop

    var title: String {
        switch self {
        case .still: String(localized: "Still image")
        case .loop: String(localized: "Motion loop")
        }
    }

    /// How long a loop runs.
    static let loopSeconds = 20
    /// Its frame rate.
    static let loopFramesPerSecond = 30
}
