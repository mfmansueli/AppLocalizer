//
//  AutopilotRun+Skips.swift
//  AppLocalizer
//

import Foundation

/// Capture and Pick when the run doesn't need them: everything comes from
/// the reused captures and picks, or the run has nothing to capture.
extension AutopilotRun {
    /// Nothing to capture or record: every target settled by reused
    /// captures, or none at all.
    var skipsCapture: Bool {
        reusesEveryTarget && plan.recordingTargets.isEmpty
    }

    /// Every target comes from the reused captures, or there are none.
    var reusesEveryTarget: Bool {
        var left = plan.targets
        if plan.reusesCaptures, let kept = keptFrom {
            // Only the last run's captures count, not the ones made since.
            let reused = Set(captures.filter { $0.receivedAt <= kept.capturedAt && plan.fits($0) }.map(\.target))
            left.removeAll(where: reused.contains)
        }
        return left.isEmpty
    }

    /// Pick shows the screenshots: there are new captures to pick from.
    var picksScreens: Bool {
        !plan.pickedScreens.isEmpty && !reusesEveryTarget
    }

    /// Pick shows the App Preview recording's moments.
    var picksMoments: Bool { !plan.recordingTargets.isEmpty }

    /// Nothing for the person to pick: no new captures and no recording.
    var skipsPick: Bool {
        !picksScreens && !picksMoments
    }

    /// "Skipped · reuses the Oct 28 captures", "Skipped · nothing to
    /// capture"; nil when the run captures.
    var captureSkipNote: String? {
        guard skipsCapture else { return nil }
        guard let date = keptDate, !plan.targets.isEmpty else { return String(localized: "Skipped · nothing to capture") }
        return String(localized: "Skipped · reuses the \(date) captures")
    }

    /// "Skipped · uses the Oct 28 picks", "Skipped · no new screenshots";
    /// nil when the person picks.
    var pickSkipNote: String? {
        guard skipsPick else { return nil }
        if let date = keptDate, !plan.targets.isEmpty, reusesEveryTarget { return String(localized: "Skipped · uses the \(date) picks") }
        return String(localized: "Skipped · no new screenshots")
    }

    /// "Skipped · no App Preview", "Skipped · nothing moves in this run",
    /// "Skipped: approved as made"; nil when the person watches it.
    var watchSkipNote: String? { watchSkipNote(design: designKind) }

    /// At Plan, with the design project Start will use: with it, a motion
    /// header becomes a loop to watch.
    func watchSkipNote(design: DesignProjectKind) -> String? {
        let loop = watchesHeaderLoop(design: design)
        if plan.previewDisplays.isEmpty, !loop {
            // A loop AppLocalizer animates itself (no design AI) moves but
            // isn't watched.
            return plan.alsoMakes.makesArtwork && plan.alsoMakes.makesMotion
                ? String(localized: "Skipped · no App Preview")
                : String(localized: "Skipped · nothing moves in this run")
        }
        if !plan.stopsToWatchPreview, stage != .watchPreview { return String(localized: "Skipped: approved as made") }
        return nil
    }

    /// The run only records for its App Preview.
    var onlyRecords: Bool { plan.targets.isEmpty && !plan.recordingTargets.isEmpty }

    /// "Oct 28", when the reused captures were made.
    var keptDate: String? {
        keptFrom?.capturedAt.formatted(.dateTime.month(.abbreviated).day())
    }
}
