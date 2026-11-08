//
//  ScreenshotStudioModel+Autopilot.swift
//  AppLocalizer
//

import AppKit
import CoreGraphics
import Foundation

/// The Autopilot sheet's actions and what its stages draw.
extension ScreenshotStudioModel {
    // MARK: - Plan

    func updatePlan(_ change: (inout AutopilotPlan) -> Void) {
        autopilot?.updatePlan(for: app.id, change)
    }

    /// Start Autopilot: AppLocalizer starts Claude Code when its helper is
    /// saved; otherwise the prompt goes on the clipboard for the assistant.
    /// A run with nothing to capture goes straight to Design, and Claude
    /// Code starts only when something is left for it there.
    func start() {
        noteStoreNames()
        fillHeaderTemplates()
        autopilot?.start(appID: app.id, interfaceGaps: run.map { interfaceGaps(for: $0.plan) } ?? [])
        reportMissingSimulators()
        viewedStep = nil
        launchedRunID = nil
        // A first run has no screens yet: Claude Code picks them, so it
        // starts like any run that captures.
        if let run, !run.plan.awaitsScreens, run.remainingTargets.isEmpty, run.remainingRecordings.isEmpty {
            startWithoutCapturing()
            return
        }
        guard let launcher, launcher.canStart else {
            copyPrompt()
            return
        }
        let prompt = prompt
        Task { await launch(prompt, with: launcher) }
    }

    /// Each language's App Store name on the run, so its header, search
    /// and App Preview write the name that language's page has.
    func noteStoreNames() {
        autopilot?.noteStoreNames(storeTexts.names, appID: app.id)
    }

    /// iPad, iPhone Duo and Mac captured in only some of `plan`'s languages
    /// so far: the run captures the rest.
    func interfaceGaps(for plan: AutopilotPlan) -> [AutopilotInterfaceGap] {
        AutopilotInterfaceGap.gaps(in: plan, captures: screenshots.document?.captures ?? CaptureIndex())
    }

    private func startWithoutCapturing() {
        guard let autopilot else { return }
        let context = context
        let appID = app.id
        let prompt = prompt
        Task {
            await autopilot.skipCapturingIfDone(appID, context: context)
            guard autopilot.run(for: appID)?.assistantHasWork == true else { return }
            guard let launcher, launcher.canStart else {
                copyPrompt()
                return
            }
            await launch(prompt, with: launcher)
        }
    }

    /// With no folder chosen nothing starts, so it's back to the plan; if
    /// the helper went away, it's the paste after all. AppLocalizer starts
    /// Claude Code again if it stops with work left.
    private func launch(_ prompt: String, with launcher: ClaudeCodeLauncher) async {
        // Marked first: the session can end before `start` returns.
        autopilot?.update(app.id) { $0.startsClaudeCode = true }
        if let id = await launcher.start(.autopilot, appID: app.id, appName: app.name, prompt: prompt) {
            launchedRunID = id
            return
        }
        autopilot?.update(app.id) { $0.startsClaudeCode = nil }
        if launcher.canStart {
            stop()
        } else {
            copyPrompt()
        }
    }

    /// The newest Claude Code AppLocalizer started for this Autopilot run:
    /// the first, or one that continued it.
    var launchedRun: ClaudeCodeRun? {
        guard let run, let launcher else { return nil }
        return launcher.latestRun(appID: app.id, purpose: .autopilot, since: run.startedAt) ?? launcher.run(launchedRunID)
    }

    // MARK: - Keeping it going

    /// Why nobody is working on the run although the assistant has work,
    /// or nil.
    var stall: AutopilotStall? {
        guard let run else { return nil }
        let startsItself = run.startsClaudeCode == true && launcher?.canStart == true
        return AutopilotContinuation.stall(of: run, session: launchedRun, startsItself: startsItself, now: autopilot?.now() ?? .now)
    }

    /// Someone works on the run's next step: the Claude Code AppLocalizer
    /// started is going (or AppLocalizer is starting it again), or a pasted
    /// run hasn't gone quiet. Not after Claude Code failed, which says so
    /// with Try Again. Design's cards only spin while it does.
    var assistantIsWorking: Bool {
        guard let run, run.assistantHasWork, stall == nil else { return false }
        return launchedRun?.failure == nil
    }

    /// Continue: AppLocalizer starts Claude Code where the run stopped;
    /// without the helper, the prompt that continues it is copied.
    func continueRun() {
        guard let autopilot else { return }
        guard let launcher, launcher.canStart else {
            NSPasteboard.general.clearContents()
            let prompt = run.map { AutopilotPrompt.continuing($0, appName: app.name) } ?? AutopilotPrompt.continuing(appName: app.name, appID: app.id)
            NSPasteboard.general.setString(prompt, forType: .string)
            didCopyPrompt = true
            return
        }
        let (appID, name) = (app.id, app.name)
        Task { await AutopilotContinuation.start(appID: appID, appName: name, center: autopilot, launcher: launcher) }
    }

    /// After the person's answer or step: Claude Code continues with what
    /// they left it to do (`AutopilotContinuation.keepGoing`).
    func keepGoing() async {
        await goingOn()()
    }

    /// `keepGoing` for a step's task, which can end after the section
    /// closed: it holds the center and the app, never the studio, whose
    /// view model is unowned.
    func goingOn() -> @MainActor () async -> Void {
        let (center, appID, appName) = (autopilot, app.id, app.name)
        return { [weak launcher = self.launcher] in
            guard let center, let launcher else { return }
            await AutopilotContinuation.keepGoing(appID: appID, appName: appName, center: center, launcher: launcher)
        }
    }

    /// Cancel on the plan: the sheet closes and the last run comes back.
    func cancelPlan() {
        autopilot?.cancelPlan(for: app.id)
        isAutopilotPresented = false
    }

    /// Cancel Run and Stop: back to the plan, and Claude Code stops too.
    func stop() {
        autopilot?.stop(appID: app.id)
        viewedStep = nil
        if let run = launchedRun, run.isActive { launcher?.stop(run.id) }
    }

    /// Cancel Run… after Capture: what this Mac makes stops, the run goes
    /// back to its plan with its captures and picks, and Claude Code stops.
    func cancelRun() {
        autopilot?.cancelRun(appID: app.id)
        viewedStep = nil
        if let run = launchedRun, run.isActive { launcher?.stop(run.id) }
    }

    /// What stopped when AppLocalizer closed picks up (the Screenshots
    /// section opening).
    func resumeInterruptedWork() {
        autopilot?.resumeInterruptedWork(app.id, context: context)
    }

    // MARK: - Prompt

    /// What to paste into the assistant to start.
    var prompt: String {
        guard let run else { return "" }
        return AutopilotPrompt.start(appName: app.name, appID: app.id, plan: run.plan)
    }

    /// The prompt's shortcut in Claude Code.
    static let promptShortcut = "/mcp__applocalizer__run_screenshots"

    func copyPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
        didCopyPrompt = true
    }

    // MARK: - Capture

    func resolve(_ problem: AutopilotProblem, with resolution: AutopilotProblemResolution) {
        resolve(AutopilotProblemGroup(problems: [problem]), with: resolution)
    }

    /// The same answer for every problem with one cause.
    func resolve(_ group: AutopilotProblemGroup, with resolution: AutopilotProblemResolution) {
        guard let autopilot else { return }
        let context = context
        let appID = app.id
        let ids = group.problems.map(\.id)
        let goOn = goingOn()
        Task {
            await autopilot.resolveProblems(appID: appID, problemIDs: ids, with: resolution, context: context)
            await goOn()
        }
    }

    /// Record Again: the App Preview recordings the assistant left out are
    /// made once more, by the Claude Code AppLocalizer starts again.
    func recordAgain() {
        guard let autopilot else { return }
        autopilot.update(app.id) { $0.recordSkippedAgain() }
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// Upload One by Hand…: the PNG becomes the screen's capture.
    func upload(_ url: URL, for problem: AutopilotProblem) async {
        guard let autopilot else { return }
        do {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let file = try await screenshots.services.storeCapture(data, for: app)
            let report = AutopilotCaptureReport(target: problem.target, notes: String(localized: "Uploaded by hand"))
            _ = try await autopilot.receiveCapture(appID: app.id, file: file, report: report, context: context)
            await autopilot.resolveProblem(appID: app.id, problemID: problem.id, with: .uploadedByHand, context: context)
            await keepGoing()
        } catch {
            screenshots.notice = error.localizedDescription
        }
    }

    /// A capture's image, loaded on demand.
    func image(for capture: AutopilotCapture?, width: Int) -> CGImage? {
        guard let capture, let run else { return nil }
        let record = capture.screenshotCapture(slot: run.plan.slot(of: capture.target.screenID) ?? 0)
        if let image = screenshots.captureImages.image(for: record, width: width) { return image }
        screenshots.captureImages.request([record], width: width)
        return nil
    }

    // MARK: - Pick

    func pick(_ capture: AutopilotCapture, for screenID: String) {
        autopilot?.pick(capture.id, for: screenID, appID: app.id)
    }

    func usePicks() {
        guard let autopilot else { return }
        let context = context
        viewedStep = nil
        let appID = app.id
        let goOn = goingOn()
        Task {
            await autopilot.usePicks(appID: appID, context: context)
            await goOn()
        }
    }

    // MARK: - Choose

    func useDirection(_ direction: AutopilotDirection) {
        guard let autopilot else { return }
        let context = context
        viewedStep = nil
        let appID = app.id
        let goOn = goingOn()
        Task {
            await autopilot.useDirection(direction.id, appID: appID, context: context)
            await goOn()
        }
    }

    /// Under Ask for changes, when the run makes header and search
    /// artwork: what a note can change, and that the loops' motion is
    /// AppLocalizer's own.
    var revisionScopeNote: String? {
        guard let run, run.plan.alsoMakes.makesArtwork else { return nil }
        let plan = run.plan
        let extras = plan.alsoMakes
        if run.usesConcepts { return Self.conceptScopeNote(run) }
        let scope = plan.makesScreenshots
            ? String(localized: "A note changes the screenshots and the header and search images: colors, type, layout and what they show.")
            : String(localized: "A note changes the header and search images: colors, type, layout and what they show. The live screenshots stay as they are.")
        guard extras.makesMotion else { return scope }
        let motion = String(localized: """
        The loops move the way AppLocalizer animates them (slow light, twinkling stars, a gentle float); the motion \
        itself can’t change yet.
        """)
        return scope + " " + motion
    }

    /// Ask Claude Design: the note goes back to the design AI.
    func askForChanges() {
        // With header concepts, the note is for every concept and direction.
        if let run, run.usesConcepts {
            autopilot?.requestConceptChanges(revisionNote, conceptIDs: run.conceptList.map(\.id), forDirections: true, appID: app.id)
        } else {
            autopilot?.requestRevision(revisionNote, appID: app.id)
        }
        revisionNote = ""
        viewedStep = nil
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// The direction's five screenshots in the primary language, laid out
    /// with the picks. Its laurels show the App Store rating once it's
    /// looked up, and none where the app has no ratings yet, as the set
    /// will.
    func layouts(for direction: AutopilotDirection) -> [ScreenshotLayout] {
        guard let run else { return [] }
        screenshots.lookUpRatings(for: direction.template)
        screenshots.lookUpReviews(for: direction.template)
        let store = screenshots.ratings.hashValue ^ screenshots.reviews.hashValue
        let key = "\(direction.id)@\(direction.receivedAt.timeIntervalSinceReferenceDate)#\(store)"
        if let cached = directionLayouts[key] { return cached }
        let engine = screenshots.layoutEngine
        var template = direction.template
        template.slots = AutopilotLocalizer.slots(template.slots, count: run.plan.screens.count)
        let display = run.plan.displayTypes.first ?? .iPhone
        let layouts = run.plan.screens.indices.map { slot in
            let screen = run.plan.screens[slot]
            let caption = screenshots.document?.captions.caption(locale: primaryLocale.code, slot: slot)
                ?? (screen.caption.isEmpty ? nil : ScreenshotCaption(headline: screen.caption, subhead: nil, provenance: .written))
            return engine.layout(template, slot: slot, locale: primaryLocale, displayType: display, caption: caption)
        }
        directionLayouts[key] = layouts
        return layouts
    }

    /// In a Two phones slot of `direction`, the picked capture of the
    /// screen before it, standing behind (the last for the first), as the
    /// Look preview and the rendered set draw it; nil in any other slot.
    func behindCapture(in direction: AutopilotDirection, slot: Int) -> AutopilotCapture? {
        guard let run else { return nil }
        let count = run.plan.screens.count
        let slots = AutopilotLocalizer.slots(direction.template.slots, count: count)
        guard slots.indices.contains(slot) else { return nil }
        var template = direction.template
        template.slots = slots
        guard let behind = template.behindSlot(slot, templateSlot: slot, count: count) else { return nil }
        return run.pickedCapture(for: run.plan.screens[behind].id)
    }

    /// The picked capture of each screen, in slot order.
    var pickedCaptures: [AutopilotCapture?] {
        guard let run else { return [] }
        return run.plan.screens.map { run.pickedCapture(for: $0.id) }
    }

    /// The first Apple Vision Pro screenshot in `direction`: its window
    /// under the caption of the iPhone screen it shows. Nil unless the plan
    /// has Apple Vision Pro.
    func visionPreview(for direction: AutopilotDirection) -> (layout: ScreenshotLayout, capture: AutopilotCapture?)? {
        guard let run, run.plan.displayTypes.contains(.visionPro), let screen = run.plan.screens(on: .visionPro).first else { return nil }
        let capture = run.finalCapture(for: AutopilotCaptureTarget(screenID: screen.id, displayType: .visionPro, locale: run.plan.primaryLocale))
        let key = "vision-\(direction.id)@\(direction.receivedAt.timeIntervalSinceReferenceDate)-\(capture?.id ?? "")#\(screenshots.ratings.hashValue ^ screenshots.reviews.hashValue)"
        if let cached = directionLayouts[key]?.first { return (cached, capture) }
        let slot = screen.sourceScreenID.flatMap { run.plan.slot(of: $0) } ?? 0
        var template = direction.template
        template.slots = AutopilotLocalizer.slots(template.slots, count: run.plan.screens.count)
        let caption = screenshots.document?.captions.caption(locale: primaryLocale.code, slot: slot)
            ?? Self.caption(run.plan.caption(of: screen))
        let layout = screenshots.layoutEngine.layout(
            template, slot: min(slot, max(template.slots.count - 1, 0)), locale: primaryLocale, displayType: .visionPro,
            caption: caption, captureSize: capture?.pixelSize
        )
        directionLayouts[key] = [layout]
        return (layout, capture)
    }

    /// The first Apple Watch screen's pick, shown as it is: the watch has
    /// no captions.
    var watchPreviewCapture: AutopilotCapture? {
        guard let run, run.plan.displayTypes.contains(.watch), let screen = run.plan.screens(on: .watch).first else { return nil }
        return run.pickedCapture(for: screen.id)
    }

    private static func caption(_ headline: String) -> ScreenshotCaption? {
        headline.isEmpty ? nil : ScreenshotCaption(headline: headline, subhead: nil, provenance: .written)
    }

    // MARK: - Ready

    /// Make Again: the artwork that couldn't be made, made again from what
    /// the person chose; the set reloads once the run is ready again.
    func makeExtrasAgain() {
        guard let autopilot else { return }
        let (appID, context) = (app.id, context)
        Task { await autopilot.makeExtrasAgain(appID: appID, context: context) }
    }

    /// See the Preview: the new set in the preview.
    func seePreview() {
        isAutopilotPresented = false
        // Held strongly: the task may run after the section closes.
        Task { [screenshots] in
            await screenshots.reloadDocument()
            choice = .new
        }
    }
}
