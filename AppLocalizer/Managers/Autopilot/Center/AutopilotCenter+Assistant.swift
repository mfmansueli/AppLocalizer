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
    /// solved, and captures from before that problem (out of date, say)
    /// give way to this one. Moves on when the last one arrives.
    func receiveCapture(
        appID: StoreApp.ID, file: CaptureFile, report: AutopilotCaptureReport, context: AutopilotContext
    ) async throws -> AutopilotCapture {
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else {
            throw AutopilotError(String(localized: "The run isn’t capturing now. Call next_step to see what AppLocalizer wants."))
        }
        let target = run.plan.resolvedTarget(report.target, size: file.pixelSize)
        try Self.checkSize(file.pixelSize, for: target.displayType, duoPose: run.plan.duoPose(for: target))
        var capture = AutopilotCapture(
            id: makeID(), target: target, attempt: max(1, report.attempt), score: min(max(report.score, 0), 1), notes: report.notes,
            captureID: file.id, pixelSize: file.pixelSize, receivedAt: now()
        )
        let name = run.plan.screen(id: target.screenID)?.name ?? target.screenID
        let slot = (run.plan.slot(of: target.screenID) ?? 0) + 1
        capture.text = await readText(of: capture, slot: slot - 1, context: context)
        update(appID) { run in
            let reported = run.problems.filter { $0.target == target && ($0.isOpen || $0.resolution == .retryWithFix) }.map(\.reportedAt).max()
            if let reported { run.captures.removeAll { $0.target == target && $0.receivedAt < reported } }
            run.captures.removeAll { $0.target == target && $0.attempt == capture.attempt }
            // The Duo opened or folded since its last capture.
            if let pose = run.plan.duoPose(for: target),
               run.captures.last(where: { $0.target.displayType == .iPhoneDuo }).flatMap({ run.plan.duoPose(for: $0.target) }) != pose
            {
                run.appendLog(pose.launchLine(locale: target.locale), kind: .command, at: now())
            }
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
    /// screen on the same device waits in the other languages (every
    /// screen on it, when the whole device can't be captured: that one
    /// problem takes the place of the device's others).
    func reportProblem(
        appID: StoreApp.ID, target: AutopilotCaptureTarget, what: String, proposedFix: String?, refusedCommand: String? = nil,
        changesProject: Bool? = nil, affectsDevice: Bool? = nil
    ) throws -> AutopilotProblem {
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else {
            throw AutopilotError(String(localized: "The run isn’t capturing now. Call next_step to see what AppLocalizer wants."))
        }
        // On iPhone Duo, a target sent without its pose takes its screen's
        // first, as the plan's targets have it.
        var target = target
        if target.duoPose == nil { target.duoPose = run.plan.duoPose(for: target) }
        let problem = AutopilotProblem(
            id: "pr-" + makeID().prefix(8), target: target, what: what, proposedFix: proposedFix,
            refusedCommand: refusedCommand.flatMap { $0.isEmpty ? nil : $0 }, changesProject: changesProject,
            affectsDevice: affectsDevice == true ? true : nil, reportedAt: now()
        )
        let name = run.plan.screen(id: target.screenID)?.name ?? target.screenID
        update(appID) { run in
            run.problems.removeAll { open in
                open.isOpen && (open.target == target || (problem.isDeviceWide && open.target.displayType == target.displayType))
            }
            run.problems.append(problem)
            let place = problem.isDeviceWide ? target.displayType.title : "\(name) (\(target.locale))"
            run.appendLog("\(place): \(what)", kind: .problem, at: now())
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
                case .retryWithFix where problem.fixIsCommand:
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

    /// Leave a device out of this run (not iPhone): its screens stop being
    /// captured, its problems close, and the run goes on without it. The
    /// next plan has it off too, until the person turns it back on.
    func leaveOut(_ display: ScreenshotDisplayType, appID: StoreApp.ID, context: AutopilotContext) async {
        guard display != .iPhone, let run = runs[appID], run.stage == .capture || run.stage == .waiting else { return }
        update(appID) { run in
            run.plan.setPlans(display, false)
            for index in run.problems.indices where run.problems[index].isOpen && run.problems[index].target.displayType == display {
                run.problems[index].resolution = .leftOut
            }
            run.appendLog(String(localized: "\(display.title) left out of this run"), kind: .event, at: now())
        }
        await advance(appID, context: context)
    }

    // MARK: - Next step

    /// What the assistant should do now. A waiting run is picked up.
    func nextStep(appID: StoreApp.ID, client: String, environment: AutopilotEnvironment? = nil) async -> AutopilotNextStep {
        guard let run = runs[appID] else { return .noRun }
        switch run.stage {
        case .plan:
            return planStep(run)
        case .waiting:
            pickUp(appID: appID, client: client, environment: environment)
            // A run that only records for its App Preview starts recording.
            return capturingStep(runs[appID] ?? run)
        case .capture:
            return capturingStep(appID: appID, run, environment: environment)
        case .pick:
            return .wait(reason: personStepReason(run.stage), seconds: 20)
        case .choose:
            return retakeStep(run) ?? .wait(reason: personStepReason(run.stage), seconds: 20)
        case .design:
            return retakeStep(run) ?? designStep(run)
        case .localize:
            return localizeStep(run)
        case .watchPreview:
            return watchStep(run)
        case .ready:
            return readyStep(appID: appID, run, client: client)
        }
    }

    /// Done, unless the person asked for a variant in Review & Push: the
    /// first time it's handed over, the sheet says the assistant read it.
    private func readyStep(appID: StoreApp.ID, _ run: AutopilotRun, client: String) -> AutopilotNextStep {
        guard let request = run.variantRequest else { return .done }
        if request.readAt == nil { markVariantRead(appID: appID, client: client) }
        return .designVariant(request)
    }

    /// Capturing, with the environment the assistant reports kept.
    private func capturingStep(appID: StoreApp.ID, _ run: AutopilotRun, environment: AutopilotEnvironment?) -> AutopilotNextStep {
        if let environment { update(appID) { $0.environment = environment } }
        return capturingStep(run)
    }

    /// At the plan, only Suggest Screens asks the assistant something;
    /// once its suggestions are in, its part is done.
    private func planStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if let request = run.screenRequest { return .suggestScreens(request) }
        return run.screenSuggestions != nil ? .done : .noRun
    }

    /// The moments the person asked to record again, before designing.
    private func retakeStep(_ run: AutopilotRun) -> AutopilotNextStep? {
        let ids = run.retakeTargets.map(\.screenID)
        guard !ids.isEmpty else { return nil }
        var seen: Set<String> = []
        return .recordAgain(screenIDs: ids.filter { seen.insert($0).inserted })
    }

    /// Watching the App Preview: the person's changes for the design
    /// source, else wait for them.
    private func watchStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if let review = run.loopReview, review.approvedAt == nil {
            if review.isRemaking {
                return .wait(reason: String(localized: "AppLocalizer is making the header loop again."), seconds: 10)
            }
            if let request = review.request, run.designKind.usesDesignAI { return .reviseLoop(note: request.note) }
        }
        if let review = run.previewReview, review.remake != nil {
            return .wait(reason: String(localized: "AppLocalizer is making the App Preview again."), seconds: 10)
        }
        if let review = run.previewReview, let request = review.request, run.designKind.usesDesignAI {
            return .revisePreview(note: request.note, review: review)
        }
        return .wait(reason: String(localized: "The person is watching the App Preview."), seconds: 20)
    }

    private func personStepReason(_ stage: AutopilotStage) -> String {
        stage == .pick ? String(localized: "The person is picking the best captures.") : String(localized: "The person is choosing a direction.")
    }

    private func localizeStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if !run.overflows.isEmpty { return .writeCaptions(run.overflows) }
        if let needs = run.artworkTextNeeds, !needs.isEmpty { return .writeArtworkTexts(needs) }
        if let review = run.loopReview, review.waitsToMake, review.isAnimating, run.designKind.usesDesignAI {
            return .animateHeader(conceptID: review.conceptID)
        }
        if let extras = run.extrasProgress, !extras.isFinished {
            return .wait(reason: String(localized: "AppLocalizer is making the header and search artwork and the App Preview."), seconds: 10)
        }
        return .wait(reason: String(localized: "AppLocalizer is rendering and checking every screenshot."), seconds: 5)
    }

    /// The rehearsal first, then the other languages.
    private func captureStep(_ run: AutopilotRun) -> AutopilotNextStep {
        .capture(targets: run.nextTargets, retries: run.retries)
    }

    /// Capturing: what's left, then the App Preview's recordings, else wait
    /// for a problem or the next stage.
    private func capturingStep(_ run: AutopilotRun) -> AutopilotNextStep {
        if !run.remainingTargets.isEmpty || !run.retries.isEmpty { return captureStep(run) }
        if !run.remainingRecordings.isEmpty { return .record(targets: run.remainingRecordings) }
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
        let remaining = max(run.expectedDirections - run.directions.count, 0)
        if run.usesConcepts, run.conceptsLeft > 0 || remaining > 0 { return .design(remaining: remaining) }
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
                if !run.plan.targets.isEmpty {
                    run.appendLog(String(localized: "Captured \(run.capturedCount) of \(run.totalCaptures)"), kind: .event, at: now())
                }
                // A run with no new captures and no recording has nothing to pick.
                run.stage = run.plan.stopsToPick && !run.skipsPick ? .pick : .design
            }
            if runs[appID]?.stage == .design { await beginDesign(appID, context: context) }
        case .design where run.hasAllDirections && run.hasAllConcepts && run.revision == nil:
            await finishDesign(run, context: context)
        default:
            break
        }
    }

    /// Everything designed: on to Choose, or straight on when there's
    /// nothing to choose (a kept template) or the run doesn't stop for it.
    private func finishDesign(_ run: AutopilotRun, context: AutopilotContext) async {
        let appID = run.appID
        // A kept template and no header to choose: nothing to choose.
        if !run.choosesDirection, !run.usesConcepts, let only = run.directions.first {
            await useDirection(only.id, appID: appID, context: context)
        } else if run.plan.stopsToChoose {
            update(appID) { $0.stage = .choose }
        } else if run.usesConcepts {
            // Unattended: the recommended header and the first direction.
            takeRecommendedConcept(appID)
            update(appID) { run in
                if run.directionPick == nil { run.directionPick = run.directions.first?.id }
            }
            await useChoices(appID: appID, context: context)
        } else if let first = run.directions.first {
            await useDirection(first.id, appID: appID, context: context)
        }
    }

    /// Apple Watch Ultra's two screenshot sizes.
    static let watchSizes = [PixelSize(width: 422, height: 514), PixelSize(width: 410, height: 502)]

    /// The size a capture of `display` must have, either way up. Apple
    /// Watch takes an Ultra's screen; an Apple Vision Pro capture is the
    /// app's window, any shape at least 600 px on its short side; iPhone
    /// Duo's is its inner display's for an open screen and its cover
    /// display's for a closed one (`duoPose`).
    static func checkSize(_ size: PixelSize, for display: ScreenshotDisplayType, duoPose: AutopilotDuoPose? = nil) throws {
        switch display {
        case .watch:
            guard !watchSizes.contains(size) else { return }
            throw AutopilotError(String(localized: "A \(size.title) capture doesn’t fit Apple Watch, which takes \(watchSizes[0].title) or \(watchSizes[1].title). Capture on \(display.deviceName)."))
        case .visionPro:
            guard min(size.width, size.height) < 600 else { return }
            throw AutopilotError(String(localized: "A \(size.title) capture is too small for Apple Vision Pro. Capture the app’s window at its default size."))
        case .iPhoneDuo where duoPose == .closed:
            guard !CaptureSizeRules.isDuoOuterDisplay(size) else { return }
            let cover = CaptureSizeRules.duoOuterSize
            throw AutopilotError(String(localized: """
            A \(size.title) capture isn’t iPhone Duo’s cover display. This screen is one of its closed screenshots: capture it \
            closed, on the \(cover.title) cover display (a UI test’s own screenshot is that display).
            """))
        case .iPhoneDuo where CaptureSizeRules.isDuoOuterDisplay(size):
            throw AutopilotError(String(localized: """
            A \(size.title) capture is iPhone Duo’s cover display. This screen is one of its open screenshots: capture the \
            inner display, \(display.portraitPixelSize.title) or \(display.portraitPixelSize.rotated.title), with the Duo open.
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
