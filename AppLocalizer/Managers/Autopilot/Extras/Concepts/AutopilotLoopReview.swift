//
//  AutopilotLoopReview.swift
//  AppLocalizer
//

import Foundation

/// The header loop of a run with a motion loop: Claude Design animates the
/// chosen concept's pages once the person chose it (the motion prompt),
/// AppLocalizer makes the loops in every language, and the person watches
/// them in "Watch the header loop" (v1, then v2, v3… for each change they
/// ask for) and approves.
struct AutopilotLoopReview: Codable, Hashable, Sendable {
    /// The concept being animated.
    var conceptID: String
    /// 1 once the first animated pages arrived.
    var version = 0
    /// Newest last.
    var revisions: [AutopilotLoopRevision] = []
    /// Ask for changes, waiting for `revise_artwork_concept`.
    var request: AutopilotRevisionRequest?
    /// Localize has everything else and waits for the animated pages to
    /// make the loops.
    var waitsToMake = false
    /// AppLocalizer is making the loops again with a new version.
    var isRemaking = false
    var approvedAt: Date?
    /// Animated pages refused for a motion check: the next try with the
    /// same failure is taken, with a warning.
    var motionRetries = 0
    /// The motion checks the loop is taken without, one line each.
    var motionWarnings: [String]?

    /// Claude Design hasn't sent the animated pages yet.
    var isAnimating: Bool { version == 0 }

    /// Approve and Ask wait.
    var isBusy: Bool { isAnimating || request != nil || isRemaking }
}
