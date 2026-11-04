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
    /// Header style: where the concepts come from; nil (plans from before)
    /// is templates. Use `artworkStyle`.
    var style: AutopilotArtworkStyle?
    /// The scene templates picked, in order (up to 3); nil until the plan
    /// fills in its first picks. Use `headerTemplates`.
    var templates: [AutopilotHeaderTemplate]?
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
    var makesMotion: Bool { makesArtwork && artworkMotion == .loop && artworkSize.allowsMotion }

    /// The expected result, empty when there's none.
    var artworkDirection: AutopilotArtworkDirection {
        get { direction ?? AutopilotArtworkDirection() }
        set { direction = newValue.isEmpty ? nil : newValue }
    }

    /// Motion loop switches one 16:9 image to 21:9 and 3:2; the header or
    /// search alone stays as it is.
    mutating func setMotion(_ motion: AutopilotArtworkMotion) {
        artworkMotion = motion
        if motion == .loop, !artworkSize.allowsMotion { artworkSize = .headerAndSearch }
    }

    /// One 16:9 image for both switches back to still.
    mutating func setArtworkSize(_ size: AutopilotArtworkSize) {
        artworkSize = size
        if !size.allowsMotion { artworkMotion = .still }
    }

    /// Templates unless the person chose Go freely.
    var artworkStyle: AutopilotArtworkStyle {
        get { style ?? .templates }
        set { style = newValue }
    }

    /// The scene templates picked, in order; none until the plan fills in
    /// its first picks.
    var headerTemplates: [AutopilotHeaderTemplate] {
        get { templates ?? [] }
        set { templates = newValue }
    }

    /// The concepts a run's design step makes: one per picked template, or
    /// three of the design source's own.
    var conceptCount: Int {
        artworkStyle == .free ? AutopilotRun.directionCount : max(1, headerTemplates.count)
    }

    /// Every App Preview has music: Warm acoustic unless the person chose
    /// another.
    var previewMusic: AutopilotPreviewMusic {
        get { music ?? .standard }
        set { music = newValue }
    }
}
