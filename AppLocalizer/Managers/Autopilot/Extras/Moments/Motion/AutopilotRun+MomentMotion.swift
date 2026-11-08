//
//  AutopilotRun+MomentMotion.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRun {
    mutating func noteMotion(_ found: [String: AutopilotMomentMotion]) {
        momentMotion = (momentMotion ?? [:]).merging(found) { $1 }
    }

    /// Asks for a moment again because it barely moves; once per screen.
    mutating func askAgainForMotion(_ screenID: String) {
        var asked = motionRetakes ?? []
        guard !asked.contains(screenID) else { return }
        asked.append(screenID)
        motionRetakes = asked
        askToRecordAgain(screenID)
    }

    /// The moments still to record again because they barely moved.
    var momentsWaitingForMotion: [String] {
        (motionRetakes ?? []).filter { screenID in
            pickRecordingTargets.contains { isWaitingForRetake(screenID, on: $0) }
        }
    }

    /// The chosen moments that barely move, by screen name, for Review.
    var tooStillMomentNames: [String] {
        chosenMomentIDs.filter { momentMotion?[$0]?.isTooStill == true }.map { plan.screen(id: $0)?.name ?? $0 }
    }
}
