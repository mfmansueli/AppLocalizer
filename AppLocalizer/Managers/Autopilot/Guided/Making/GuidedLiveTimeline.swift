//
//  GuidedLiveTimeline.swift
//  AppLocalizer
//

import Foundation

/// The plan's timeline while the run goes: the lines done, the one at
/// work now (animated while Autopilot works on it), and the ones to come.
/// Making it and the stepper show it, so the person can tell at a glance
/// that Autopilot is running and which step it's on.
enum GuidedLiveTimeline {
    enum State: Hashable, Sendable {
        case done
        /// Autopilot works on it now.
        case running
        /// Where the run is, waiting on the person (a stop, or a problem
        /// only they can solve).
        case current
        case upcoming
    }

    /// The timeline's order, which the run's stages follow.
    private static let order: [GuidedTimelineRow.Kind] = [.capture, .pick, .design, .choose, .localize, .review]

    /// The line the run is on; nil while it's planned.
    static func currentKind(of run: AutopilotRun) -> GuidedTimelineRow.Kind? {
        switch run.stage {
        case .plan: nil
        case .waiting, .capture: .capture
        case .pick: .pick
        case .design: .design
        case .choose: .choose
        case .localize: .localize
        case .watchPreview, .ready: .review
        }
    }

    /// Autopilot works on its own: starting the assistant, capturing,
    /// designing or localizing, with no problem waiting on the person.
    static func isWorking(_ run: AutopilotRun) -> Bool {
        switch run.stage {
        case .waiting, .capture, .design, .localize: run.openProblems.isEmpty
        case .plan, .pick, .choose, .watchPreview, .ready: false
        }
    }

    /// Each line's state. A line the plan doesn't have (Capture when the
    /// last captures are reused) passes to the next one it has.
    static func states(of rows: [GuidedTimelineRow], run: AutopilotRun) -> [GuidedTimelineRow.Kind: State] {
        guard let kind = currentKind(of: run), let position = order.firstIndex(of: kind) else {
            return Dictionary(uniqueKeysWithValues: rows.map { ($0.kind, State.upcoming) })
        }
        let current = rows.first { (order.firstIndex(of: $0.kind) ?? 0) >= position }?.kind
        let working = isWorking(run)
        var states: [GuidedTimelineRow.Kind: State] = [:]
        for row in rows {
            let index = order.firstIndex(of: row.kind) ?? 0
            states[row.kind] = if row.kind == current {
                working && !row.isYours ? .running : .current
            } else if index < position {
                .done
            } else {
                .upcoming
            }
        }
        // A finished, pushed run has nothing left at all.
        if run.stage == .ready, run.guidedReview?.pushedAt != nil {
            for row in rows { states[row.kind] = .done }
        }
        return states
    }
}
