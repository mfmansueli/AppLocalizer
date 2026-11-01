//
//  AutopilotCenter+Assistant.swift
//  AppLocalizer
//

import Foundation

/// What the assistant does: pick the plan up, send captures and problems,
/// and ask what's next.
extension AutopilotCenter {
    /// The assistant asked for the plan: a waiting run starts capturing.
    func pickUp(appID: StoreApp.ID, client: String, environment: AutopilotEnvironment?) {
        update(appID) { run in
            if let environment { run.environment = environment }
            guard run.stage == .waiting else { return }
            run.stage = .capture
            run.client = client
            run.appendLog(String(localized: "\(client) picked up the plan"), kind: .event, at: now())
        }
    }

    // MARK: - Uploads

    /// A PNG arrived at the upload link; `report_capture` names it by the
    /// returned ID.
    func registerUpload(_ file: CaptureFile, for run: AutopilotRun) -> AutopilotUpload {
        let upload = AutopilotUpload(id: "up-" + makeID().prefix(12), appID: run.appID, runID: run.id, file: file, receivedAt: now())
        uploads[upload.id] = upload
        return upload
    }

    // MARK: - Captures

    /// Records a capture of `target`; a problem on the same screen counts as
    /// solved. Moves on when the last one arrives.
    func receiveCapture(
        appID: StoreApp.ID, file: CaptureFile, report: AutopilotCaptureReport, context: AutopilotContext
    ) async throws -> AutopilotCapture {
        let target = report.target
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else {
            throw AutopilotError(String(localized: "The run isn’t capturing now. Call next_step to see what AppLocalizer wants."))
        }
        try Self.checkSize(file.pixelSize, for: target.displayType)
        var capture = AutopilotCapture(
            id: makeID(), target: target, attempt: max(1, report.attempt), score: min(max(report.score, 0), 1), notes: report.notes,
            captureID: file.id, pixelSize: file.pixelSize, receivedAt: now()
        )
        let name = run.plan.screen(id: target.screenID)?.name ?? target.screenID
        let slot = (run.plan.slot(of: target.screenID) ?? 0) + 1
        capture.text = await readText(of: capture, slot: slot - 1, context: context)
        update(appID) { run in
            run.captures.removeAll { $0.target == target && $0.attempt == capture.attempt }
            run.captures.append(capture)
            for index in run.problems.indices where run.problems[index].target == target && run.problems[index].resolution != .usePrimaryCapture {
                run.problems[index].resolution = .captured
            }
            let fileName = String(format: "%@/%@-%02d.png", target.locale, target.displayType.shortTitle, slot)
            run.appendLog(String(localized: "screenshot → \(fileName) · \(name) · attempt \(capture.attempt)"), kind: .event, at: now())
        }
        await advance(appID, context: context)
        return capture
    }

    /// What the capture's text says: its language, cut-off labels and
    /// system prompts. Apple Watch's are read too; nil when nothing could be.
    private func readText(of capture: AutopilotCapture, slot: Int, context: AutopilotContext) async -> CaptureTextFacts? {
        guard let locale = StoreLocaleCatalog.locale(code: capture.target.locale) else { return nil }
        let reading = await context.services.readText(
            of: capture.screenshotCapture(slot: slot), for: context.app, locale: locale, primary: context.primaryLocale
        )
        return reading.map { CaptureTextAnalyzer.facts(of: $0, appName: context.app.name) }
    }

    /// A screen couldn't be reached; the others keep going, but the same
    /// screen on the same device waits in the other languages.
    func reportProblem(
        appID: StoreApp.ID, target: AutopilotCaptureTarget, what: String, proposedFix: String?, refusedCommand: String? = nil,
        changesProject: Bool? = nil
    ) throws -> AutopilotProblem {
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else {
            throw AutopilotError(String(localized: "The run isn’t capturing now. Call next_step to see what AppLocalizer wants."))
        }
        let problem = AutopilotProblem(
            id: "pr-" + makeID().prefix(8), target: target, what: what, proposedFix: proposedFix,
            refusedCommand: refusedCommand.flatMap { $0.isEmpty ? nil : $0 }, changesProject: changesProject, reportedAt: now()
        )
        let name = run.plan.screen(id: target.screenID)?.name ?? target.screenID
        update(appID) { run in
            run.problems.removeAll { $0.target == target && $0.isOpen }
            run.problems.append(problem)
            run.appendLog("\(name) (\(target.locale)): \(what)", kind: .problem, at: now())
        }
        return problem
    }

    /// The person's answer to a problem: retry with the fix (which joins
    /// the plan when it's a command, not a change to the project), reuse
    /// the primary language's capture, or a capture they uploaded.
    func resolveProblem(appID: StoreApp.ID, problemID: String, with resolution: AutopilotProblemResolution, context: AutopilotContext) async {
        await resolveProblems(appID: appID, problemIDs: [problemID], with: resolution, context: context)
    }

    /// The person's answer to problems with one cause. Reusing the primary
    /// language's capture for a change to the project covers the screen on
    /// that device in every other language too: the project is as it is
    /// for this run.
    func resolveProblems(appID: StoreApp.ID, problemIDs: [String], with resolution: AutopilotProblemResolution, context: AutopilotContext) async {
        update(appID) { run in
            for problemID in problemIDs {
                guard let index = run.problems.firstIndex(where: { $0.id == problemID }) else { continue }
                run.problems[index].resolution = resolution
                let problem = run.problems[index]
                switch resolution {
                case .retryWithFix where !problem.needsProjectChange:
                    let fix = problem.proposedFix?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !fix.isEmpty, !run.plan.simulator.extraCommands.contains(fix) { run.plan.simulator.extraCommands.append(fix) }
                case .usePrimaryCapture where problem.needsProjectChange:
                    run.usePrimaryCapture(screenID: problem.target.screenID, on: problem.target.displayType)
                default:
                    break
                }
            }
        }
        await advance(appID, context: context)
    }

    // MARK: - Next step

    /// What the assistant should do now. A waiting run is picked up.
    func nextStep(appID: StoreApp.ID, client: String, environment: AutopilotEnvironment? = nil) async -> AutopilotNextStep {
        guard let run = runs[appID] else { return .noRun }
        switch run.stage {
        case .plan:
            return .noRun
        case .waiting:
            pickUp(appID: appID, client: client, environment: environment)
            return captureStep(runs[appID] ?? run)
        case .capture:
            if let environment { update(appID) { $0.environment = environment } }
            return capturingStep(run)
        case .pick, .choose:
            return .wait(reason: personStepReason(run.stage), seconds: 20)
        case .design:
            return designStep(run)
        case .localize:
            return localizeStep(run)
        case .ready:
            return .done
        }
    }

    private func personStepReason(_ stage: AutopilotStage) -> String {
        stage == .pick ? String(localized: "The person is picking the best captures.") : String(localized: "The person is choosing a direction.")
    }

    private func localizeStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if !run.overflows.isEmpty { return .writeCaptions(run.overflows) }
        return .wait(reason: String(localized: "AppLocalizer is rendering and checking every screenshot."), seconds: 5)
    }

    /// The rehearsal first, then the other languages.
    private func captureStep(_ run: AutopilotRun) -> AutopilotNextStep {
        .capture(targets: run.nextTargets, retries: run.retries)
    }

    /// Capturing: what's left, else wait for a problem or the next stage.
    private func capturingStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if !run.remainingTargets.isEmpty || !run.retries.isEmpty { return captureStep(run) }
        if let problem = run.openProblems.first {
            return .wait(reason: String(localized: "A problem waits for the person: \(problem.what)"), seconds: 15)
        }
        return .wait(reason: String(localized: "AppLocalizer is moving on to the next stage."), seconds: 5)
    }

    /// Designing: a revision first, then the directions still to come.
    private func designStep(_ run: AutopilotRun) -> AutopilotNextStep {
        guard run.designKind.usesDesignAI else {
            return .wait(reason: String(localized: "AppLocalizer is making directions from its starters."), seconds: 5)
        }
        if let revision = run.revision { return .revise(note: revision.note) }
        let remaining = AutopilotRun.directionCount - run.directions.count
        guard remaining > 0 else { return .wait(reason: String(localized: "Every direction has arrived."), seconds: 5) }
        return .design(remaining: remaining)
    }

    // MARK: - Moving on

    /// Moves a run past a stage that's done: capturing to Pick (or straight
    /// to Design with the assistant's picks), designing to Choose (or the
    /// first direction).
    func advance(_ appID: StoreApp.ID, context: AutopilotContext) async {
        guard !holdsStages, let run = runs[appID] else { return }
        switch run.stage {
        case .capture where run.isCaptureComplete:
            update(appID) { run in
                run.pickBest()
                run.appendLog(String(localized: "Captured \(run.capturedCount) of \(run.totalCaptures)"), kind: .event, at: now())
                run.stage = run.plan.stopsToPick ? .pick : .design
            }
            if runs[appID]?.stage == .design { await beginDesign(appID, context: context) }
        case .design where run.hasAllDirections && run.revision == nil:
            if run.plan.stopsToChoose {
                update(appID) { $0.stage = .choose }
            } else if let first = run.directions.first {
                await useDirection(first.id, appID: appID, context: context)
            }
        default:
            break
        }
    }

    /// Apple Watch Ultra's two screenshot sizes.
    static let watchSizes = [PixelSize(width: 422, height: 514), PixelSize(width: 410, height: 502)]

    /// The size a capture of `display` must have, either way up. Apple
    /// Watch takes an Ultra's screen; an Apple Vision Pro capture is the
    /// app's window, any shape at least 600 px on its short side; iPhone
    /// Duo's is its inner display's, the size the template renders at.
    static func checkSize(_ size: PixelSize, for display: ScreenshotDisplayType) throws {
        switch display {
        case .watch:
            guard !watchSizes.contains(size) else { return }
            throw AutopilotError(String(localized: "A \(size.title) capture doesn’t fit Apple Watch, which takes \(watchSizes[0].title) or \(watchSizes[1].title). Capture on \(display.deviceName)."))
        case .visionPro:
            guard min(size.width, size.height) < 600 else { return }
            throw AutopilotError(String(localized: "A \(size.title) capture is too small for Apple Vision Pro. Capture the app’s window at its default size."))
        case .iPhoneDuo where CaptureSizeRules.isDuoOuterDisplay(size):
            throw AutopilotError(String(localized: """
            A \(size.title) capture is iPhone Duo’s outer display. The template renders at the inner display’s \
            \(display.portraitPixelSize.title): capture the inner one, unfolded (xcrun simctl io booted screenshot --display=<its ID>).
            """))
        default:
            break
        }
        let expected = display.portraitPixelSize
        guard size == expected || size == expected.rotated else {
            throw AutopilotError(String(localized: "A \(size.title) capture doesn’t fit \(display.title), which takes \(expected.title) or \(expected.rotated.title). Capture on \(display.deviceName)."))
        }
    }
}
