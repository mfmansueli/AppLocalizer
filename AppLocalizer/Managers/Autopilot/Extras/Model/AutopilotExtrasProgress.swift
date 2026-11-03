//
//  AutopilotExtrasProgress.swift
//  AppLocalizer
//

import Foundation

/// Localize and check's rows for the extras: the header and search
/// artwork rendered in each language, and the App Previews assembled from
/// the recordings and checked against Apple's rules.
struct AutopilotExtrasProgress: Codable, Hashable, Sendable {
    var artworkDone = 0
    var artworkTotal = 0
    /// Languages whose headline doesn't fit the artwork even at its
    /// smallest size.
    var artworkTooLong: [String] = []
    /// What the artwork's checks found in every language, errors first.
    var artworkChecks: [ArtworkCheck]?
    var previewsDone = 0
    var previewsTotal = 0
    /// One sentence per App Preview that failed a check or couldn't be
    /// made.
    var previewProblems: [String] = []
    /// The primary language's App Preview length.
    var previewSeconds: Double?
    /// Each device's App Preview size, iPhone first.
    var previewSizes: [PixelSize] = []
    /// Everything is rendered, assembled and checked.
    var isFinished = false

    var isArtworkDone: Bool { artworkDone >= artworkTotal }
    var arePreviewsDone: Bool { previewsDone >= previewsTotal }
}
