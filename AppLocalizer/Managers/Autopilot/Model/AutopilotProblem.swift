//
//  AutopilotProblem.swift
//  AppLocalizer
//

import Foundation

/// A screen the assistant couldn't reach. The rest keeps going; the person
/// takes the proposed fix, reuses the primary language's capture or
/// uploads one by hand.
struct AutopilotProblem: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var target: AutopilotCaptureTarget
    /// "The photo picker asked for access and covered the entry."
    var what: String
    /// A command or step, e.g. `xcrun simctl privacy booted grant photos …`.
    var proposedFix: String?
    var resolution: AutopilotProblemResolution?
    var reportedAt: Date

    var isOpen: Bool { resolution == nil }
}
