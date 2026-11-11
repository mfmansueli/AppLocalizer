//
//  GuidedCheck.swift
//  AppLocalizer
//

import Foundation

/// A line in Review & push's Checks: passed, a change Autopilot made for
/// the person to confirm (a shortened caption, with Looks Good or Edit…),
/// something to look at, or something still being made.
struct GuidedCheck: Hashable, Sendable, Identifiable {
    enum State: Hashable, Sendable {
        case passed
        case toConfirm
        case attention
        case working
    }

    var id: String
    var text: String
    var state: State
    /// The captions shortened, for a check to confirm.
    var shortenings: [AutopilotShortening] = []
    /// What a check to look at found, one line each: "German · iPad ·
    /// Chat: Cut-off text: “Garten ver…”."
    var details: [String] = []
    /// An assistant's caption proposal waiting on the person, with Accept
    /// and Reject.
    var proposalID: String?

    /// "“Durchsuche jahrelange Tagebucheinträge in Sekunden” → “Finde
    /// alles in Sekunden”", one line each.
    var changes: [String] {
        shortenings.map { "“\($0.before)” → “\($0.after)”" }
    }
}
