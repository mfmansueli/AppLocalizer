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
    /// Settled with the primary language's capture without a problem of
    /// their own: a screen's other languages, when the person reused the
    /// primary capture for a problem that needs a change to the project.
    /// Nil in runs from before, and when there are none.
    var primaryCaptureTargets: Set<AutopilotCaptureTarget>?
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
            || primaryCaptureTargets?.contains(target) == true
            || problems.contains { $0.target == target && ($0.resolution == .usePrimaryCapture || $0.resolution == .uploadedByHand) }
    }

    var capturedCount: Int { plan.targets.count(where: isSettled) }

    /// What's left to capture, the rehearsal's first (see
    /// `AutopilotPlan.rehearsalLocale`), without the ones a problem holds.
    var remainingTargets: [AutopilotCaptureTarget] {
        let held = heldTargets
        return plan.rehearsalFirstTargets.filter { !isSettled($0) && !held.contains($0) }
    }

    /// What the assistant captures now: the rehearsal while any of it is
    /// left, then the other languages.
    var nextTargets: [AutopilotCaptureTarget] {
        let remaining = remainingTargets
        let rehearsal = remaining.filter(plan.isRehearsal)
        return rehearsal.isEmpty ? remaining : rehearsal
    }

    /// Every screen is still being tried in the primary language and the
    /// rehearsal's before the other languages.
    var isRehearsing: Bool {
        plan.rehearsalLocale != nil && remainingTargets.contains(where: plan.isRehearsal)
    }

    /// What an open problem holds back: its own target, and the same
    /// screen on the same device in the other languages, which would fail
    /// the same way (every screen on it, for a device-wide problem). A
    /// retry holds them until its capture arrives. A problem in another
    /// language doesn't hold the primary language's.
    var heldTargets: Set<AutopilotCaptureTarget> {
        var held = Set(openProblems.map(\.target))
        for problem in problems where problem.isOpen || isPendingRetry(problem) {
            if problem.isDeviceWide {
                // Every screen in every language, but a retry's own.
                held.formUnion(plan.targets.filter { $0.displayType == problem.target.displayType && $0 != problem.target })
                continue
            }
            let fromPrimary = problem.target.locale == plan.primaryLocale
            for locale in plan.capturedLocales where locale != problem.target.locale && (fromPrimary || locale != plan.primaryLocale) {
                held.insert(AutopilotCaptureTarget(screenID: problem.target.screenID, displayType: problem.target.displayType, locale: locale))
            }
        }
        return held
    }

    var openProblems: [AutopilotProblem] { problems.filter(\.isOpen) }

    /// Open problems with the same cause together: one card for a test
    /// that fails the same way in every language and on every device.
    var problemGroups: [AutopilotProblemGroup] { AutopilotProblemGroup.groups(of: openProblems) }

    /// Problems the person chose to retry: the assistant captures them again
    /// with the fix. One reported again is open instead.
    var retries: [AutopilotProblem] {
        problems.filter(isPendingRetry)
    }

    private func isPendingRetry(_ problem: AutopilotProblem) -> Bool {
        problem.resolution == .retryWithFix && plan.displayTypes.contains(problem.target.displayType)
            && !captures.contains { $0.target == problem.target }
            && !problems.contains { $0.isOpen && $0.target == problem.target }
    }

    /// Reuse the primary language's capture for a screen on a device in
    /// every other language not captured yet.
    mutating func usePrimaryCapture(screenID: String, on display: ScreenshotDisplayType) {
        var settled = primaryCaptureTargets ?? []
        for locale in plan.capturedLocales where locale != plan.primaryLocale {
            let target = AutopilotCaptureTarget(screenID: screenID, displayType: display, locale: locale)
            if !captures.contains(where: { $0.target == target }) { settled.insert(target) }
        }
        primaryCaptureTargets = settled.isEmpty ? nil : settled
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
