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
    /// AppLocalizer started Claude Code for this run, so it starts it again
    /// when it stops with work left (`AutopilotContinuation`). Nil when the
    /// prompt was pasted, and in runs from before.
    var startsClaudeCode: Bool?
    /// When the person's step last gave the assistant work again (Use These
    /// Picks, Ask for Changes, Use This Direction). A Claude Code that ended
    /// before then ended on the person's turn, not with work left
    /// (`AutopilotContinuation.stall`). Nil in runs from before.
    var handedBackAt: Date?
    /// When the assistant last read the design brief (`get_design_brief`):
    /// Design shows it has started on the directions. Nil before, and in
    /// runs from before.
    var briefReadAt: Date?
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
    /// The header and search come as concepts of their own
    /// (`propose_artwork_concept`), chosen apart from the screenshot
    /// direction. Nil in runs started before, whose directions carry their
    /// artwork (`AutopilotDirection.artworkDesign`).
    var proposesConcepts: Bool?
    /// With Motion loop, every concept is animated at Design, so the person
    /// chooses among the loops. Nil in runs started before, which animate
    /// only the chosen one, after Use These.
    var animatesConcepts: Bool?
    /// The header and search concepts, in the order they arrived; nil
    /// before the first, and in runs without them.
    var concepts: [AutopilotArtworkConcept]?
    /// The chosen concept's id: picked at Choose, used from Use These on.
    var art: String?
    /// The screenshot direction picked at Choose before Use These; nil
    /// when none is.
    var directionPick: String?
    /// The header loop, from Use These in a run with a motion loop; nil
    /// before, and in runs without one.
    var loopReview: AutopilotLoopReview?
    /// The Simulator recordings for the App Preview; nil in runs from
    /// before, and until the first arrives.
    var recordings: [AutopilotRecording]?
    /// Recordings the assistant couldn't make; nil when there are none.
    var recordingSkips: [AutopilotRecordingSkip]?
    /// The moments the person chose for the App Preview at Pick, by screen
    /// ID, in every recording; nil keeps Claude Code's suggestions.
    var previewMomentIDs: [String]?
    /// Moments the person asked to record again (screen IDs), until the
    /// new takes arrive; nil when there are none.
    var momentRetakes: [String]?
    /// The new takes of single moments, standing in for those moments of
    /// their device's recording; nil when there are none.
    var retakes: [AutopilotRecording]?
    /// How the header, search and App Preview are coming along while
    /// localizing; nil before, and in runs from before.
    var extrasProgress: AutopilotExtrasProgress?
    /// Watch the App Preview: the version shown, how it's cut, the design
    /// source's revisions; nil before the checkpoint, and in runs from
    /// before it.
    var previewReview: AutopilotPreviewReview?
    /// Captions to write or shorten before the set is ready.
    var overflows: [AutopilotOverflow] = []
    /// The placements' texts Localize waits for; nil when none (and in
    /// runs from before them).
    var artworkTextNeeds: [AutopilotArtworkTextNeed]?
    /// A Product Page Optimization variant asked of the assistant once the
    /// set is ready; nil when none is.
    var variantRequest: ArtworkVariantRequest?
    var shortenings: [AutopilotShortening] = []
    var localeStatus: [String: AutopilotLocaleStatus] = [:]
    /// The template version the chosen direction became.
    var templateVersion: Int?
    /// Captures carried over from the last run.
    var keptCaptureCount = 0
    /// The last run's captures this one can reuse; nil when there are none.
    var keptFrom: AutopilotKeptCaptures?
    /// The app's name in each language (locale → name) as its App Store
    /// page has it: what the header, the search image and the App
    /// Preview's end card write as the name (`appName(in:fallback:)`). Nil
    /// until AppLocalizer has read the page, and in runs from before.
    var storeNames: [String: String]?
    /// Suggest Screens, waiting for the assistant.
    var screenRequest: AutopilotScreenRequest?
    /// The assistant's suggested screens, shown at Plan.
    var screenSuggestions: AutopilotScreenSuggestions?
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
        captures.contains { $0.target == target && plan.fits($0) }
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

    /// What the assistant captures now: each screen on each device in the
    /// rehearsal's languages before its other languages, the rehearsal
    /// first. A screen or a device that can't go on holds back only its
    /// own other languages, never the rest of the run. iPhone Duo's closed
    /// screens come before its open ones: it starts closed.
    var nextTargets: [AutopilotCaptureTarget] {
        let remaining = remainingTargets
        let rehearsing = Set(remaining.filter(plan.isRehearsal).map { Self.place(of: $0) })
        let closedLeft = remaining.contains { plan.duoPose(for: $0) == .closed }
        return remaining.filter { target in
            if closedLeft, plan.duoPose(for: target) == .open { return false }
            return plan.isRehearsal(target) || !rehearsing.contains(Self.place(of: target))
        }
    }

    /// A screen on a device, whatever the language.
    private static func place(of target: AutopilotCaptureTarget) -> AutopilotCaptureTarget {
        AutopilotCaptureTarget(screenID: target.screenID, displayType: target.displayType, locale: "")
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
    var heldTargets: Set<AutopilotCaptureTarget> { heldTargets(byDevices: true) }

    /// `heldTargets`; without `byDevices`, only what problems with one
    /// screen hold.
    func heldTargets(byDevices: Bool) -> Set<AutopilotCaptureTarget> {
        var held = Set(openProblems.filter { byDevices || !$0.isDeviceWide }.map(\.target))
        for problem in problems where problem.isOpen || isPendingRetry(problem) {
            if problem.isDeviceWide {
                guard byDevices else { continue }
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
    /// with the fix. One reported again is open instead, and so is one on a
    /// device this Mac still can't run (an open problem for the device). A
    /// problem reported on a screen already captured (out of date, say)
    /// waits for a capture that arrives after it.
    var retries: [AutopilotProblem] {
        problems.filter(isPendingRetry)
    }

    private func isPendingRetry(_ problem: AutopilotProblem) -> Bool {
        problem.resolution == .retryWithFix && plan.displayTypes.contains(problem.target.displayType)
            && !captures.contains { $0.target == problem.target && $0.receivedAt >= problem.reportedAt }
            && !problems.contains { $0.isOpen && ($0.target == problem.target || $0.holdsDevice(of: problem)) }
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

    /// Every target settled, nothing waiting on the person, and nothing to
    /// capture again.
    var isCaptureComplete: Bool {
        // A run that only records for its App Preview has no targets.
        let hasWork = !plan.targets.isEmpty || !plan.recordingTargets.isEmpty
        return hasWork && plan.targets.allSatisfy(isSettled) && openProblems.isEmpty && retries.isEmpty && remainingRecordings.isEmpty
    }

    /// A target's captures, best first: clean text before an issue, then
    /// by score.
    func captures(for target: AutopilotCaptureTarget) -> [AutopilotCapture] {
        captures.filter { $0.target == target && plan.fits($0) }
            .map { (capture: $0, isClean: textIssues(of: $0).isEmpty) }
            .sorted { first, second in
                if first.isClean != second.isClean { return first.isClean }
                let (one, other) = (first.capture, second.capture)
                return one.score > other.score || (one.score == other.score && one.attempt < other.attempt)
            }
            .map(\.capture)
    }

    /// The plan's targets with a capture that fits: what a new run keeps.
    var keptTargetCount: Int {
        let targets = Set(plan.targets)
        return Set(captures.filter { targets.contains($0.target) && plan.fits($0) }.map(\.target)).count
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

    /// The best capture for each screen without a pick yet: reused picks
    /// stay.
    mutating func pickMissing() {
        for screen in plan.pickedScreens where !candidates(for: screen.id).contains(where: { $0.id == picks[screen.id] }) {
            if let best = candidates(for: screen.id).first { picks[screen.id] = best.id }
        }
    }

    // MARK: - Design

    var chosenDirection: AutopilotDirection? {
        directions.first { $0.id == chosenDirectionID }
    }

    /// Every direction has arrived.
    var hasAllDirections: Bool { directions.count >= expectedDirections }

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
