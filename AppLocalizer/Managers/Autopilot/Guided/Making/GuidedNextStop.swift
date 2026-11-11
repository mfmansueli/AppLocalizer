//
//  GuidedNextStop.swift
//  AppLocalizer
//

import Foundation

/// Making it's "Next for you: choose the look, in about 10 min.": the
/// person's next stop and about when, so they can walk away.
enum GuidedNextStop: Hashable, Sendable {
    case pick
    case choose
    case review

    /// The stop after where `run` is now.
    static func next(after run: AutopilotRun) -> GuidedNextStop {
        let plan = run.plan
        let before = { (stage: AutopilotStage) in run.stage.isBefore(stage) }
        if before(.pick), plan.stopsToPick, run.plan.makesScreenshots || !plan.artworkTargets.isEmpty { return .pick }
        if before(.choose), plan.stopsToChoose, GuidedPlanTimeline.hasLookToChoose(plan) { return .choose }
        return .review
    }

    var what: String {
        switch self {
        case .pick: String(localized: "pick the captures")
        case .choose: String(localized: "choose the look")
        case .review: String(localized: "review everything and push")
        }
    }

    /// About how many minutes until the stop: what's left now, then the
    /// design and localizing it waits for.
    static func minutes(to stop: GuidedNextStop, run: AutopilotRun, progress: GuidedRunProgress) -> Int {
        var minutes = progress.minutesLeft ?? 0
        let plan = run.plan
        if stop != .pick, run.stage.isBefore(.design) {
            minutes += AutopilotEstimate.designMinutes(for: run.designKind) + AutopilotEstimate.extrasDesignMinutes(for: plan)
        }
        if stop == .review, run.stage.isBefore(.localize) { minutes += GuidedMakeSummary.localizeMinutes(plan) }
        return max(1, minutes)
    }

    /// "Next for you: choose the look, in about 10 min. You can close this
    /// window; Autopilot keeps going and lets you know."
    /// With only problems left, the stop is now: the run isn't going
    /// anywhere, so no minutes.
    static func line(for run: AutopilotRun, progress: GuidedRunProgress) -> String {
        if run.waitsOnlyOnProblems {
            return String(localized: "Next for you: what’s above, now. The run waits until you retry or leave out each part; then it goes on by itself.")
        }
        let stop = next(after: run)
        let minutes = minutes(to: stop, run: run, progress: progress)
        return String(localized: "Next for you: \(stop.what), in about \(minutes) min.") + " "
            + String(localized: "You can close this window; Autopilot keeps going and lets you know.")
    }
}
