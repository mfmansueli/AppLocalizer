//
//  AppMusicPick.swift
//  AppLocalizer
//

import Foundation

/// The library track the assistant picked for the app's App Preview, from
/// what it knows of the app. The person's own choice always wins over it.
struct AppMusicPick: Codable, Hashable, Sendable {
    var track: AppPreviewTrack
    /// "Quiet and discreet: people use it alone, at night."
    var reason: String
}
