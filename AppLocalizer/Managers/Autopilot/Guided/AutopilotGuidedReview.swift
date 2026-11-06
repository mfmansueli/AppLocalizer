//
//  AutopilotGuidedReview.swift
//  AppLocalizer
//

import Foundation

/// What the person did at the guided Review & push: the parts approved,
/// the shortened captions confirmed with Looks Good, and when they pushed.
/// Kept on the run, so closing the sheet or AppLocalizer keeps it.
struct AutopilotGuidedReview: Codable, Hashable, Sendable {
    var approved: [GuidedReviewPart] = []
    /// Shortenings the person confirmed (`AutopilotGuidedReview.key`).
    var confirmed: [String] = []
    /// When Push to App Store… sent everything; nil before.
    var pushedAt: Date?

    func isApproved(_ part: GuidedReviewPart) -> Bool { approved.contains(part) }

    /// Approves `part`, or takes the approval back.
    mutating func toggle(_ part: GuidedReviewPart) {
        if let index = approved.firstIndex(of: part) {
            approved.remove(at: index)
        } else {
            approved.append(part)
        }
    }

    func isConfirmed(_ shortening: AutopilotShortening) -> Bool {
        confirmed.contains(Self.key(shortening))
    }

    mutating func confirm(_ shortenings: [AutopilotShortening]) {
        for key in shortenings.map(Self.key) where !confirmed.contains(key) {
            confirmed.append(key)
        }
    }

    /// "de-DE#2": a shortened caption by language and slot.
    static func key(_ shortening: AutopilotShortening) -> String {
        "\(shortening.locale)#\(shortening.slot)"
    }
}
