//
//  AutopilotCenter.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Screenshot Autopilot for every app: each app's run and design project,
/// shared by the Screenshots section and the assistant's tools. The
/// person plans, starts and decides here; the assistant reports captures,
/// problems and directions, and asks what's next.
@MainActor
@Observable
final class AutopilotCenter {
    static let shared: AutopilotCenter = {
        let center = AutopilotCenter(persistence: FileAutopilotPersistence())
        center.promptLog = .shared
        return center
    }()

    /// Each app's current run, or its last one.
    private(set) var runs: [StoreApp.ID: AutopilotRun]
    private(set) var designProjects: [StoreApp.ID: DesignProject]
    /// The run Run Autopilot… replaced, until Start: Cancel brings it back.
    @ObservationIgnored private var replaced: [StoreApp.ID: AutopilotRun] = [:]
    /// PNGs sent to the upload link, waiting for `report_capture`.
    @ObservationIgnored var uploads: [String: AutopilotUpload] = [:]
    /// Recordings sent to the upload link, waiting for `report_recording`.
    @ObservationIgnored var recordingUploads: [String: AutopilotRecordingUpload] = [:]
    @ObservationIgnored private let persistence: (any AutopilotPersistence)?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored var now: () -> Date = { .now }
    @ObservationIgnored var makeID: () -> String = { UUID().uuidString.lowercased() }
    /// DEBUG scenes hold a run where it is: nothing moves on by itself.
    @ObservationIgnored var holdsStages = false
    /// What each app's run is making on this Mac (the artwork, loops and
    /// App Previews), so Cancel Run can stop it (`cancellably`).
    @ObservationIgnored var making: [StoreApp.ID: (token: UUID, stop: () -> Void)] = [:]
    /// How many uses of a direction or checks of every language are going
    /// for each app: a resume waits until none is (`resumeInterruptedWork`).
    @ObservationIgnored var localizing: [StoreApp.ID: Int] = [:]
    /// Where the header and search prompts, answers and renders are
    /// logged; nil logs nothing (tests, DEBUG scenes).
    @ObservationIgnored var promptLog: ArtworkPromptLog?
    /// Called when a change moves a run to another stage, with the stage
    /// it was at: the guided Autopilot's "Autopilot needs you"
    /// notifications. Nil in tests and DEBUG scenes.
    @ObservationIgnored var onStageChange: (@MainActor (AutopilotRun, AutopilotStage) -> Void)?

    init(persistence: (any AutopilotPersistence)? = nil, runs: [StoreApp.ID: AutopilotRun] = [:], designProjects: [StoreApp.ID: DesignProject] = [:]) {
        self.persistence = persistence
        let archive = persistence?.load() ?? AutopilotArchive()
        // A plan left open follows the rules made since it was saved.
        let saved = archive.runs.mapValues { run in
            var run = run.withDuoPoses()
            guard run.stage == .plan else { return run }
            run.plan = AutopilotPlanner.applyingRules(to: run.plan)
            return run
        }
        self.runs = saved.merging(runs) { $1 }
        self.designProjects = archive.designProjects.merging(designProjects) { $1 }
    }

    // MARK: - Reading

    func run(for appID: StoreApp.ID) -> AutopilotRun? {
        runs[appID]
    }

    func designProject(for appID: StoreApp.ID) -> DesignProject? {
        designProjects[appID]
    }

    /// The run whose upload link has `token`, while it takes captures.
    func run(uploadToken token: String) -> AutopilotRun? {
        runs.values.first { $0.uploadToken == token && ($0.stage == .waiting || $0.stage == .capture) }
    }

    // MARK: - Design project

    /// Connect a Design Project: nil (or No design project) uses the
    /// starters.
    func setDesignProject(_ project: DesignProject?, for appID: StoreApp.ID) {
        designProjects[appID] = project?.kind == DesignProjectKind.none ? nil : project
        scheduleSave()
    }

    /// What the design AI found in the project. While a run designs, its
    /// log says so.
    func setDesignSummary(_ summary: DesignSourceSummary, for appID: StoreApp.ID) {
        guard var project = designProjects[appID] else { return }
        project.summary = summary
        designProjects[appID] = project
        scheduleSave()
        update(appID) { run in
            guard run.stage == .design else { return }
            run.appendLog(String(localized: "Read the design project: \(summary.title)"), kind: .event, at: now())
        }
    }

    // MARK: - Planning

    /// Run Autopilot…: a new run at Plan, keeping the last run's captures
    /// that still fit. A run in progress is kept, and so is an open plan,
    /// with the rules made since (iPhone Duo).
    @discardableResult
    func prepare(appID: StoreApp.ID, versionString: String, plan: AutopilotPlan) -> AutopilotRun {
        if var current = runs[appID], current.stage != .ready {
            guard current.stage == .plan else { return current }
            current.plan = AutopilotPlanner.applyingRules(to: current.plan)
            current.keptCaptureCount = current.keptTargetCount
            runs[appID] = current
            scheduleSave()
            return current
        }
        let previous = runs[appID]
        let project = designProjects[appID]
        var run = AutopilotRun(
            id: makeID(), appID: appID, versionString: versionString, stage: .plan, plan: plan,
            designKind: project?.kind ?? .none, designName: project?.displayName,
            uploadToken: Self.makeToken(), createdAt: now()
        )
        if let previous {
            replaced[appID] = previous
            let targets = Set(plan.targets)
            run.captures = previous.captures.filter { targets.contains($0.target) }
            run.keptCaptureCount = run.keptTargetCount
            // Kept for "Reuse … captures"; Start drops them otherwise.
            let kept = previous.captures.filter { targets.contains($0.target) }
            if let latest = kept.map(\.receivedAt).max() {
                run.picks = previous.picks.filter { plan.screen(id: $0.key) != nil }
                run.keptFrom = AutopilotKeptCaptures(
                    versionString: previous.versionString, capturedAt: latest,
                    displayTypes: plan.displayTypes.filter { display in kept.contains { $0.target.displayType == display } },
                    localeCount: Set(kept.map(\.target.locale)).count, hasPicks: !run.picks.isEmpty
                )
            }
            run.environment = previous.environment
            run.client = previous.client
        }
        runs[appID] = run
        scheduleSave()
        return run
    }

    /// The Plan step's edits.
    func updatePlan(for appID: StoreApp.ID, _ change: (inout AutopilotPlan) -> Void) {
        guard var run = runs[appID], run.stage == .plan else { return }
        change(&run.plan)
        run.keptCaptureCount = run.keptTargetCount
        runs[appID] = run
        scheduleSave()
    }

    /// Cancel on the Plan step: brings back the run it replaced.
    func cancelPlan(for appID: StoreApp.ID) {
        guard let run = runs[appID], run.stage == .plan else { return }
        if let previous = replaced.removeValue(forKey: appID) {
            runs[appID] = previous
        } else if run.startedAt == nil {
            runs[appID] = nil
        }
        scheduleSave()
    }

    /// Start Autopilot: waits for the assistant to pick the plan up.
    func start(appID: StoreApp.ID) {
        guard var run = runs[appID], run.stage == .plan else { return }
        replaced[appID] = nil
        let project = designProjects[appID]
        run.designKind = project?.kind ?? .none
        run.designName = project?.displayName
        applyCaptureChoice(to: &run)
        // A design AI makes the header and search as concepts of their own.
        run.proposesConcepts = AutopilotRun.proposesConcepts(plan: run.plan, design: run.designKind) ? true : nil
        // With Motion loop, the person chooses among moving concepts.
        run.animatesConcepts = run.proposesConcepts == true && run.plan.alsoMakes.makesMotion ? true : nil
        if run.proposesConcepts == true, run.plan.alsoMakes.artworkStyle == .templates, run.plan.alsoMakes.headerTemplates.isEmpty {
            run.plan.alsoMakes.headerTemplates = AutopilotHeaderTemplate.defaultPicks(recommended: .night)
        }
        // Templates picked for the screenshots, or none: the design source's own.
        if run.plan.screenshotStyle == .templates, run.plan.screenshotTemplates.isEmpty { run.plan.runChoice.shotStyle = .free }
        run.stage = .waiting
        run.startedAt = now()
        run.finishedAt = nil
        run.uploadToken = Self.makeToken()
        runs[appID] = run
        scheduleSave()
    }

    /// Cancel Run (waiting) and Stop (capturing): back to the plan; the
    /// captures are kept for the next start.
    func stop(appID: StoreApp.ID) {
        guard var run = runs[appID], run.stage == .waiting || run.stage == .capture else { return }
        run.stage = .plan
        run.problems.removeAll(where: \.isOpen)
        run.keptCaptureCount = run.keptTargetCount
        runs[appID] = run
        scheduleSave()
    }

    // MARK: - Changing a run

    /// Applies `change` to the app's run and saves.
    func update(_ appID: StoreApp.ID, _ change: (inout AutopilotRun) -> Void) {
        guard var run = runs[appID] else { return }
        let stage = run.stage
        change(&run)
        runs[appID] = run
        scheduleSave()
        if run.stage != stage { onStageChange?(run, stage) }
    }

    /// Puts a run in place as it is (DEBUG scenes, tests).
    func install(_ run: AutopilotRun) {
        runs[run.appID] = run
        scheduleSave()
    }

    // MARK: - Saving

    private func scheduleSave() {
        guard persistence != nil else { return }
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        persistence?.save(AutopilotArchive(runs: runs, designProjects: designProjects))
    }

    /// A random secret for an upload link.
    static func makeToken() -> String {
        (0..<2).map { _ in UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased() }.joined()
    }
}
