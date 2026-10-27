//
//  PrivacyScan.swift
//  AppLocalizer
//

import Foundation

/// One assistant's pass over the project (`propose_privacy_answers`'s
/// `scan`): where it looked, what it found, and what changed since the scan
/// before it. The scan summary popover shows it.
struct PrivacyScan: Hashable, Codable, Sendable {
    /// e.g. "Claude Code".
    var assistant: String
    /// e.g. "northpier/lumen".
    var repository: String?
    /// e.g. "4f2c91a".
    var commit: String?
    var ranAt: Date
    var sdks: [PrivacySDK] = []
    /// e.g. "Lumen/PrivacyInfo.xcprivacy".
    var manifestsRead: [String] = []
    /// What it found of NSPrivacyTracking, NSUserTrackingUsageDescription,
    /// ATTrackingManager and ASIdentifierManager.
    var trackingSignals: String?
    /// What it couldn't see, e.g. "Your servers: what they keep, and for
    /// how long".
    var couldNotSee: String?
    /// Answers it suggested, and questions it asked, over the whole scan.
    var suggestionCount = 0
    var questionCount = 0
    /// Filled in when the scan ends, against the scan before it.
    var changes: PrivacyScanChanges?

    /// "northpier/lumen @ 4f2c91a".
    var source: String? {
        guard let repository else { return commit }
        return commit.map { "\(repository) @ \($0)" } ?? repository
    }
}
