//
//  AutopilotRun.swift
//  AppLocalizer
//

import Foundation

/// One Screenshot Autopilot run of an app: the plan, every capture, pick,
/// direction and problem, and where it is. Kept after it ends, so running
/// again only redoes what changed.
struct AutopilotRun: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var appID: StoreApp.ID
    /// "1.4".
    var versionString: String
    var stage: AutopilotStage
    var plan: AutopilotPlan
    /// The design source when the run started.
    var designKind: DesignProjectKind
    /// "Northpier Brand"; nil for the starters.
    var designName: String?
    /// The assistant that picked the plan up, e.g. "Claude Code".
    var client: String?
    var environment: AutopilotEnvironment?
    /// The secret in the upload link the assistant sends captures to.
    var uploadToken: String
    var captures: [AutopilotCapture] = []
    var problems: [AutopilotProblem] = []
    var log: [AutopilotLogEntry] = []
    /// Screen ID → the picked capture's ID (on the first device, in the
    /// primary language). The pick's attempt applies to every language and
    /// device.
    var picks: [String: String] = [:]
    var directions: [AutopilotDirection] = []
    var revision: AutopilotRevisionRequest?
    var chosenDirectionID: String?
    /// Captions to write or shorten before the set is ready.
    var overflows: [AutopilotOverflow] = []
    var shortenings: [AutopilotShortening] = []
    var localeStatus: [String: AutopilotLocaleStatus] = [:]
    /// The template version the chosen direction became.
    var templateVersion: Int?
    /// Captures carried over from the last run.
    var keptCaptureCount = 0
    var createdAt: Date
    var startedAt: Date?
    var finishedAt: Date?

    /// Directions a design step makes.
    static let directionCount = 3

    // MARK: - Capture

    var totalCaptures: Int { plan.targets.count }

    /// Captured, or settled by the person (the primary language's capture
    /// reused, or one uploaded by hand).
    func isSettled(_ target: AutopilotCaptureTarget) -> Bool {
        captures.contains { $0.target == target }
            || problems.contains { $0.target == target && ($0.resolution == .usePrimaryCapture || $0.resolution == .uploadedByHand) }
    }

    var capturedCount: Int { plan.targets.count(where: isSettled) }

    /// What's left to capture, without the screens waiting on a problem.
    var remainingTargets: [AutopilotCaptureTarget] {
        let blocked = Set(openProblems.map(\.target))
        return plan.targets.filter { !isSettled($0) && !blocked.contains($0) }
    }

    var openProblems: [AutopilotProblem] { problems.filter(\.isOpen) }

    /// Problems the person chose to retry: the assistant captures them again
    /// with the fix.
    var retries: [AutopilotProblem] {
        problems.filter { problem in
            problem.resolution == .retryWithFix && !captures.contains { $0.target == problem.target }
        }
    }

    /// Every target settled and nothing waiting on the person.
    var isCaptureComplete: Bool {
        !plan.targets.isEmpty && plan.targets.allSatisfy(isSettled) && openProblems.isEmpty
    }

    /// A target's captures, best first: clean text before an issue, then
    /// by score.
    func captures(for target: AutopilotCaptureTarget) -> [AutopilotCapture] {
        captures.filter { $0.target == target }
            .map { (capture: $0, isClean: textIssues(of: $0).isEmpty) }
            .sorted { first, second in
                if first.isClean != second.isClean { return first.isClean }
                let (one, other) = (first.capture, second.capture)
                return one.score > other.score || (one.score == other.score && one.attempt < other.attempt)
            }
            .map(\.capture)
    }

    var latestCapture: AutopilotCapture? {
        captures.max { $0.receivedAt < $1.receivedAt }
    }

    // MARK: - Pick

    /// Where picks are made: the screen's first device, in the primary
    /// language.
    func pickTarget(for screenID: String) -> AutopilotCaptureTarget {
        AutopilotCaptureTarget(screenID: screenID, displayType: plan.display(of: screenID) ?? .iPhone, locale: plan.primaryLocale)
    }

    /// The candidates for a screen, best first.
    func candidates(for screenID: String) -> [AutopilotCapture] {
        captures(for: pickTarget(for: screenID))
    }

    /// The picked capture, or the best one.
    func pickedCapture(for screenID: String) -> AutopilotCapture? {
        let candidates = candidates(for: screenID)
        return candidates.first { $0.id == picks[screenID] } ?? candidates.first
    }

    /// The capture a target uses in the set: the picked attempt when that
    /// language and device has it and its text is clean, else its best. An
    /// Apple Vision Pro window follows its iPhone screen's pick.
    func finalCapture(for target: AutopilotCaptureTarget) -> AutopilotCapture? {
        let own = captures(for: target)
        let attempt = pickedCapture(for: plan.pickScreenID(for: target.screenID))?.attempt
        let same = own.first { $0.attempt == attempt }
        if let same, textIssues(of: same).isEmpty { return same }
        return own.first { textIssues(of: $0).isEmpty } ?? same ?? own.first
    }

    /// The assistant's ranking: the best capture of every screen.
    mutating func pickBest() {
        for screen in plan.pickedScreens {
            if let best = candidates(for: screen.id).first { picks[screen.id] = best.id }
        }
    }

    // MARK: - Design

    var chosenDirection: AutopilotDirection? {
        directions.first { $0.id == chosenDirectionID }
    }

    /// Every direction has arrived.
    var hasAllDirections: Bool { directions.count >= Self.directionCount }

    // MARK: - Localize

    /// Screenshots in the set: every screen, device and language.
    var totalScreenshots: Int { plan.screensPerLanguage * plan.localeCodes.count }

    /// Screenshots of the languages checked so far.
    var checkedScreenshots: Int {
        plan.localeCodes.count { localeStatus[$0]?.isDone == true } * plan.screensPerLanguage
    }

    // MARK: - Log

    mutating func appendLog(_ text: String, kind: AutopilotLogEntry.Kind = .command, at date: Date) {
        log.append(AutopilotLogEntry(date: date, text: text, kind: kind))
        if log.count > 400 { log.removeFirst(log.count - 400) }
    }
}
