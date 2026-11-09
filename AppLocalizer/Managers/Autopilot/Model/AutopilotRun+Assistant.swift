//
//  AutopilotRun+Assistant.swift
//  AppLocalizer
//

import Foundation

/// Whether the assistant still has something to do, and when it last sent
/// something: what keeps a run going when Claude Code stops early.
extension AutopilotRun {
    /// The assistant has a step it can take now: picking the plan up,
    /// capturing what's left or retried, designing, revising (a direction
    /// or the App Preview), or writing captions. Not when the run waits on
    /// the person or is done.
    var assistantHasWork: Bool {
        switch stage {
        case .waiting:
            true
        case .capture:
            // The App Preview's recordings too: Claude Code is started
            // again for the ones left (Record Again).
            plan.awaitsScreens || !remainingTargets.isEmpty || !retries.isEmpty || !remainingRecordings.isEmpty
        case .design:
            !retakeTargets.isEmpty || designKind.usesDesignAI && (revision != nil || directions.count < expectedDirections) || conceptsLeft > 0
        case .localize:
            !overflows.isEmpty || artworkTextNeeds?.isEmpty == false || loopReview?.isAnimating == true
        case .watchPreview:
            reviser != nil && (previewReview?.request != nil && previewReview?.remake == nil
                || loopReview?.request != nil && loopReview?.isRemaking == false)
        case .ready:
            variantRequest != nil
        case .plan:
            screenRequest != nil
        case .choose:
            !retakeTargets.isEmpty
        case .pick:
            false
        }
    }

    /// Captures still to take or take again.
    var capturesLeft: Int {
        Set(remainingTargets).union(retries.map(\.target)).count
    }

    /// Directions still to design: none while revising, which changes the
    /// ones that arrived.
    var directionsLeft: Int {
        max(expectedDirections - directions.count, 0)
    }

    /// The last time the assistant sent a capture, a problem, a direction
    /// or an App Preview revision.
    var lastNewsAt: Date? {
        let dates = captures.map(\.receivedAt) + problems.map(\.reportedAt) + directions.map(\.receivedAt) + (retakes ?? []).map(\.receivedAt)
            + conceptList.map(\.receivedAt) + (previewReview?.revisions.map(\.madeAt) ?? []) + (loopReview?.revisions.map(\.madeAt) ?? [])
        return dates.max()
    }

    /// Where a run's quiet time counts from: its last news, the person's
    /// step that gave the assistant work again, or the assistant reading
    /// the design brief; the run's start before any of them. Picking for an
    /// hour doesn't make the design quiet.
    var lastActivityAt: Date? {
        [lastNewsAt, handedBackAt, briefReadAt].compactMap(\.self).max() ?? startedAt
    }

    /// The assistant sent something since `date`: a session that did made
    /// progress, so starting it again is worth it.
    func hasNews(since date: Date) -> Bool {
        guard let last = lastNewsAt else { return false }
        return last >= date
    }
}
