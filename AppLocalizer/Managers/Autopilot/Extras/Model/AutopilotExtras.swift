//
//  AutopilotExtras.swift
//  AppLocalizer
//

import Foundation

/// The plan's "Also make · optional": product page header and search
/// results artwork, and an App Preview video. Both are off until the person
/// turns them on; each is made by the run's design source in the chosen
/// direction, checked like the screenshots, and waits in Review & Push.
struct AutopilotExtras: Codable, Hashable, Sendable {
    var makesArtwork = false
    var artworkSize: AutopilotArtworkSize = .headerAndSearch
    var makesAppPreview = false
    var previewLanguages: AutopilotPreviewLanguages = .primary
    /// The App Preview's music; nil (plans from before) is Warm acoustic.
    /// Use `previewMusic`.
    var music: AutopilotPreviewMusic?
    /// Still image or motion loop; nil (plans from before) is still. Use
    /// `artworkMotion`.
    var motion: AutopilotArtworkMotion?
    /// What the search artwork shows; nil is a phone with the app. Use
    /// `artworkShows`.
    var shows: AutopilotArtworkShow?
    /// The expected result: the person's words and references; nil when
    /// there are none.
    var direction: AutopilotArtworkDirection?
    /// The devices App Previews are made for, when the plan has them.
    static let previewDisplays: [ScreenshotDisplayType] = [.iPhone, .iPad]
    /// How long an App Preview is made: Apple takes 15 to 30 seconds.
    static let previewSeconds = 24

    /// Neither is on.
    var isEmpty: Bool { !makesArtwork && !makesAppPreview }

    /// Still unless the person chose Motion loop.
    var artworkMotion: AutopilotArtworkMotion {
        get { motion ?? .still }
        set { motion = newValue }
    }

    /// A phone with the app unless the person chose otherwise.
    var artworkShows: AutopilotArtworkShow {
        get { shows ?? .phone }
        set { shows = newValue }
    }

    /// The header and search artwork moves: a loop at 21:9 and 3:2 (Apple
    /// takes no 16:9 video).
    var makesMotion: Bool { makesArtwork && artworkMotion == .loop && artworkSize != .wide }

    /// The expected result, empty when there's none.
    var artworkDirection: AutopilotArtworkDirection {
        get { direction ?? AutopilotArtworkDirection() }
        set { direction = newValue.isEmpty ? nil : newValue }
    }

    /// Motion loop switches the sizes to 21:9 and 3:2; still keeps them.
    mutating func setMotion(_ motion: AutopilotArtworkMotion) {
        artworkMotion = motion
        if motion == .loop { artworkSize = .headerAndSearch }
    }

    /// One 16:9 image for both switches back to still.
    mutating func setArtworkSize(_ size: AutopilotArtworkSize) {
        artworkSize = size
        if size == .wide { artworkMotion = .still }
    }

    /// Every App Preview has music: Warm acoustic unless the person chose
    /// another.
    var previewMusic: AutopilotPreviewMusic {
        get { music ?? .standard }
        set { music = newValue }
    }
}
