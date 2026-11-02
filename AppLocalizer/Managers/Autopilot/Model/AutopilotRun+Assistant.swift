//
//  AutopilotRun+Assistant.swift
//  AppLocalizer
//

import Foundation

/// Whether the assistant still has something to do, and when it last sent
/// something: what keeps a run going when Claude Code stops early.
extension AutopilotRun {
    /// The assistant has a step it can take now: picking the plan up,
    /// capturing what's left or retried, designing, revising, or writing
    /// captions. Not when the run waits on the person or is done.
    var assistantHasWork: Bool {
        switch stage {
        case .waiting:
            true
        case .capture:
            !remainingTargets.isEmpty || !retries.isEmpty
        case .design:
            designKind.usesDesignAI && (revision != nil || directions.count < Self.directionCount)
        case .localize:
            !overflows.isEmpty
        case .plan, .pick, .choose, .ready:
            false
        }
    }

    /// Captures still to take or take again.
    var capturesLeft: Int {
        Set(remainingTargets).union(retries.map(\.target)).count
    }

    /// The last time the assistant sent a capture, a problem or a direction.
    var lastNewsAt: Date? {
        let dates = captures.map(\.receivedAt) + problems.map(\.reportedAt) + directions.map(\.receivedAt)
        return dates.max()
    }

    /// The assistant sent something since `date`: a session that did made
    /// progress, so starting it again is worth it.
    func hasNews(since date: Date) -> Bool {
        guard let last = lastNewsAt else { return false }
        return last >= date
    }
}
