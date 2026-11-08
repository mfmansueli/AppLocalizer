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
    /// Why the header and search artwork couldn't be made; nothing of it
    /// was saved, so Ready for review offers Make Again.
    var artworkProblem: String?
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
    /// When the artwork's languages started, and the App Previews: the
    /// pace so far says how long the rest takes.
    var artworkStartedAt: Date?
    var previewsStartedAt: Date?
    /// When the last artwork language was finished.
    var artworkDoneAt: Date?

    var isArtworkDone: Bool { artworkDone >= artworkTotal }
    var arePreviewsDone: Bool { previewsDone >= previewsTotal }

    /// Minutes until every artwork language is made: the pace up to the
    /// last one finished, less the time since it, so the figure counts
    /// down between languages (each takes minutes) instead of climbing.
    /// Before the first, `estimate` less the time gone.
    func artworkMinutesLeft(estimate: Double, now: Date) -> Double {
        guard artworkTotal > artworkDone else { return 0 }
        let left = Double(artworkTotal - artworkDone)
        guard let start = artworkStartedAt else { return estimate * left / Double(artworkTotal) }
        guard artworkDone > 0 else { return max(0, estimate - now.timeIntervalSince(start) / 60) }
        guard let last = artworkDoneAt else { return now.timeIntervalSince(start) / Double(artworkDone) * left / 60 }
        let each = last.timeIntervalSince(start) / Double(artworkDone)
        return max(0, (each * left - now.timeIntervalSince(last)) / 60)
    }
}
