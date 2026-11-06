//
//  GuidedRunProgress.swift
//  AppLocalizer
//

import Foundation

/// Making it's one bar and one sentence: "Capturing in Simulator", "5 of
/// 10 captures · about 6 min left". Times are estimates: from how fast the
/// run has gone so far once something has arrived, else from the plan.
struct GuidedRunProgress: Hashable, Sendable {
    var title: String
    /// 0–1.
    var fraction: Double
    var line: String
    /// About how many minutes until the next part is done; nil when
    /// nothing is left to wait for.
    var minutesLeft: Int?

    static func make(_ run: AutopilotRun, now: Date) -> GuidedRunProgress {
        switch run.stage {
        case .plan, .waiting:
            waiting(run)
        case .capture:
            capture(run, now: now)
        case .pick:
            GuidedRunProgress(
                title: String(localized: "Pick the captures"), fraction: 1,
                line: String(localized: "Captured. \(run.client ?? String(localized: "The assistant"))’s picks are already selected.")
            )
        case .design:
            design(run)
        case .choose:
            GuidedRunProgress(title: String(localized: "Choose the look"), fraction: 1, line: "")
        case .localize:
            localize(run, now: now)
        case .watchPreview, .ready:
            GuidedRunProgress(title: String(localized: "Made and checked"), fraction: 1, line: "")
        }
    }

    /// Before anything arrives the plan says how long capturing and
    /// recording take: MB Admin's run said "Next for you: choose the look,
    /// in about 4 min" with about 14 min of capturing still to come.
    private static func waiting(_ run: AutopilotRun) -> GuidedRunProgress {
        let client = run.client ?? String(localized: "Claude Code")
        let kept = run.plan.reusesCaptures ? run.keptCaptureCount : 0
        let capturing = run.plan.makesScreenshots || !run.plan.artworkTargets.isEmpty
            ? AutopilotEstimate.captureMinutes(for: run.plan, kept: kept) : 0
        let left = capturing + AutopilotEstimate.recordingMinutes(for: run.plan)
        return GuidedRunProgress(
            title: String(localized: "Starting \(client)"), fraction: 0.02,
            line: String(localized: "\(client) opens the project and starts Simulator") + aboutLeft(left),
            minutesLeft: left > 0 ? left : nil
        )
    }

    private static func capture(_ run: AutopilotRun, now: Date) -> GuidedRunProgress {
        let total = run.totalCaptures
        // The assistant reads the project and picks the screens first:
        // MB Admin's run said "Recording in Simulator · 0 of 2 recordings"
        // while it did.
        if run.plan.awaitsScreens { return choosingScreens(run) }
        // A run that only records for its App Preview, or whose captures
        // are all in and only its recordings are left.
        guard total > 0, run.capturedCount < total || run.remainingRecordings.isEmpty else { return recording(run) }
        let done = run.capturedCount
        // The pace from the first capture (building the app and picking the
        // screens come before it), with pauses cut short.
        let since = activeStart(of: run.captures.map(\.receivedAt).sorted(), now: now)
        let left = (minutesLeft(done: done, total: total, since: since, now: now)
            ?? AutopilotEstimate.captureMinutes(for: total - done)) + recordingMinutesLeft(run)
        let line = String(localized: "\(done) of \(total) captures") + aboutLeft(left)
        return GuidedRunProgress(title: String(localized: "Capturing in Simulator"), fraction: fraction(done, total), line: line, minutesLeft: left)
    }

    private static func recording(_ run: AutopilotRun) -> GuidedRunProgress {
        let recordings = run.plan.recordingTargets.count
        let done = max(0, recordings - run.remainingRecordings.count)
        let left = max(1, recordingMinutesLeft(run))
        return GuidedRunProgress(
            title: String(localized: "Recording the App Preview"), fraction: fraction(done, recordings),
            line: String(localized: "\(done) of \(recordings) recordings") + aboutLeft(left), minutesLeft: left
        )
    }

    private static func choosingScreens(_ run: AutopilotRun) -> GuidedRunProgress {
        let client = run.client ?? String(localized: "Claude Code")
        let left = AutopilotEstimate.captureMinutes(for: run.plan) + recordingMinutesLeft(run)
        return GuidedRunProgress(
            title: String(localized: "Picking the screens"), fraction: 0.04,
            line: String(localized: "\(client) reads the project and picks the screens that show the app best") + aboutLeft(left),
            minutesLeft: left
        )
    }

    private static func design(_ run: AutopilotRun) -> GuidedRunProgress {
        let directions = run.expectedDirections
        let concepts = run.expectedConcepts
        let madeDirections = min(run.directions.count, directions)
        let madeConcepts = min(run.designedConcepts.count, concepts)
        var parts: [String] = []
        if directions > 0 {
            parts.append(run.plan.makesScreenshots
                ? String(localized: "\(madeDirections) of \(directions) screenshot looks")
                : String(localized: "\(madeDirections) of \(directions) looks"))
        }
        if concepts > 0 { parts.append(String(localized: "\(madeConcepts) of \(concepts) headers")) }
        let total = directions + concepts
        let done = madeDirections + madeConcepts
        let full = AutopilotEstimate.designMinutes(for: run.designKind) + AutopilotEstimate.extrasDesignMinutes(for: run.plan)
        let left = share(of: full, left: total - done, total: total)
        let title = if let brand = run.designName, run.designKind.usesDesignAI {
            String(localized: "Designing in \(brand)")
        } else {
            String(localized: "Designing")
        }
        let line = (parts.isEmpty ? String(localized: "Designing") : parts.joined(separator: " · ")) + aboutLeft(left)
        return GuidedRunProgress(title: title, fraction: fraction(done, total), line: line, minutesLeft: left)
    }

    private static func localize(_ run: AutopilotRun, now _: Date) -> GuidedRunProgress {
        let total = run.plan.localeCodes.count
        let done: Int
        if run.plan.makesScreenshots {
            done = run.plan.localeCodes.count { run.localeStatus[$0]?.isDone == true }
        } else if !run.plan.artworkKinds.isEmpty {
            done = min(run.extrasProgress?.artworkDone ?? 0, total)
        } else {
            let previews = run.extrasProgress
            done = previews.map { $0.previewsTotal > 0 ? total * $0.previewsDone / $0.previewsTotal : 0 } ?? 0
        }
        let left = share(of: GuidedMakeSummary.localizeMinutes(run.plan), left: total - done, total: total)
        let line = (total == 1
            ? String(localized: "\(done) of 1 language")
            : String(localized: "\(done) of \(total) languages")) + aboutLeft(left)
        return GuidedRunProgress(title: String(localized: "Localizing and checking"), fraction: fraction(done, total), line: line, minutesLeft: left)
    }

    // MARK: - Helpers

    /// The App Preview's recordings still to make, as their share of the
    /// plan's recording time.
    static func recordingMinutesLeft(_ run: AutopilotRun) -> Int {
        let recordings = run.plan.recordingTargets.count
        let left = run.remainingRecordings.count
        guard recordings > 0, left > 0 else { return 0 }
        return share(of: AutopilotEstimate.recordingMinutes(for: run.plan), left: left, total: recordings)
    }

    /// From the pace so far: the time each capture took, for what's left.
    static func minutesLeft(done: Int, total: Int, since start: Date?, now: Date) -> Int? {
        guard let start, done > 0, total > done else { return total > done ? nil : 0 }
        let perCapture = now.timeIntervalSince(start) / Double(done)
        return max(1, Int((perCapture * Double(total - done) / 60).rounded(.up)))
    }

    /// A pause longer than this (a problem waiting on the person, the app
    /// quit, Claude Code stopped) counts as only this long.
    static let longestGap: TimeInterval = 10 * 60

    /// When capturing started had nothing paused: the time since the first
    /// capture, with every gap between captures (and since the last one)
    /// cut to `longestGap`. A run left for days used to say "about 4,414 min
    /// left".
    static func activeStart(of times: [Date], now: Date) -> Date? {
        guard var previous = times.first else { return nil }
        var elapsed: TimeInterval = 0
        for time in times.dropFirst() + [now] {
            elapsed += min(max(0, time.timeIntervalSince(previous)), longestGap)
            previous = max(previous, time)
        }
        return now.addingTimeInterval(-elapsed)
    }

    /// The part of `minutes` that `left` of `total` takes: a minute at
    /// least.
    static func share(of minutes: Int, left: Int, total: Int) -> Int {
        let part = Double(minutes) * Double(max(left, 0)) / Double(max(total, 1))
        return max(1, Int(part.rounded(.up)))
    }

    /// " · about 6 min left", " · about 1 h 20 min left".
    static func aboutLeft(_ minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        guard minutes >= 60 else { return " · " + String(localized: "about \(minutes) min left") }
        let hours = minutes / 60
        let rest = minutes % 60
        return " · " + (rest == 0
            ? String(localized: "about \(hours) h left")
            : String(localized: "about \(hours) h \(rest) min left"))
    }

    private static func fraction(_ done: Int, _ total: Int) -> Double {
        total > 0 ? min(1, Double(done) / Double(total)) : 0
    }
}
