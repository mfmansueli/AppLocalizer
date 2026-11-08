//
//  AutopilotLoopProgress.swift
//  AppLocalizer
//

import Foundation

/// What the header loop is waiting for after the person asked for changes:
/// the design source revising it, then AppLocalizer drawing it in every
/// language. Bruma's run said "Claude Design is revising the loop" for the
/// hour after Claude Design had finished, with Approve off and no time.
struct AutopilotLoopProgress: Hashable, Sendable {
    /// "Claude Design is revising the loop: “slower”.", "Making the new
    /// loop".
    var title: String
    var detail: String
    /// 0–1 while AppLocalizer makes it; nil while the design source works.
    var fraction: Double?
    /// "7 of 12 languages · about 31 min left"; empty while the design
    /// source works.
    var line: String
    /// Under Approve, off until the loop is made.
    var approveNote: String
    /// About how many minutes are left once AppLocalizer is making it.
    var minutesLeft: Int?

    /// Nil when the loop isn't waiting for anything.
    static func make(_ run: AutopilotRun, now: Date) -> AutopilotLoopProgress? {
        guard let review = run.loopReview, review.approvedAt == nil else { return nil }
        let designer = (run.reviser ?? run.designKind).title
        // The request stays until the loops are made, so this comes first.
        if review.isRemaking { return making(run, designer: designer, now: now) }
        guard let request = review.request else { return nil }
        return revising(run, designer: designer, note: request.note)
    }

    private static func revising(_ run: AutopilotRun, designer: String, note: String) -> AutopilotLoopProgress {
        let total = run.plan.localeCodes.count
        let minutes = max(1, Int(AutopilotEstimate.artworkMinutes(for: run.plan).rounded(.up)))
        let about = GuidedRunProgress.about(minutes)
        return AutopilotLoopProgress(
            title: String(localized: "\(designer) is revising the loop: “\(note)”."),
            detail: total == 1
                ? String(localized: "The still and the name stay as approved. Then AppLocalizer makes it, \(about).")
                : String(localized: "The still and the name stay as approved. Then AppLocalizer makes it in \(total) languages, \(about)."),
            line: "",
            approveNote: String(localized: "You can approve once the new loop is made.")
        )
    }

    private static func making(_ run: AutopilotRun, designer: String, now: Date) -> AutopilotLoopProgress {
        var extras = run.extrasProgress ?? AutopilotExtrasProgress()
        if extras.artworkTotal == 0 { extras.artworkTotal = run.plan.localeCodes.count }
        let total = extras.artworkTotal
        let done = min(extras.artworkDone, total)
        let left = extras.artworkMinutesLeft(estimate: AutopilotEstimate.artworkMinutes(for: run.plan), now: now)
        let minutes = max(1, Int(left.rounded(.up)))
        let aboutLeft = GuidedRunProgress.aboutLeft(minutes)
        let count = total == 1 ? String(localized: "\(done) of 1 language") : String(localized: "\(done) of \(total) languages")
        return AutopilotLoopProgress(
            title: String(localized: "Making the new loop"),
            detail: String(localized: """
            \(designer) sent the new version. Each language is drawn frame by frame on this Mac and checked; until \
            they’re all made, you’re watching the earlier loop.
            """),
            fraction: total > 0 ? Double(done) / Double(total) : 0,
            line: count + aboutLeft,
            approveNote: String(localized: "You can approve once the new loop is made") + aboutLeft,
            minutesLeft: minutes
        )
    }
}
