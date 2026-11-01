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
    func start() {
        autopilot?.start(appID: app.id)
        viewedStep = nil
        launchedRunID = nil
        guard let launcher, launcher.canStart else {
            copyPrompt()
            return
        }
        let prompt = prompt
        Task { await launch(prompt, with: launcher) }
    }

    /// With no folder chosen nothing starts, so it's back to the plan; if
    /// the helper went away, it's the paste after all.
    private func launch(_ prompt: String, with launcher: ClaudeCodeLauncher) async {
        if let id = await launcher.start(.autopilot, appID: app.id, appName: app.name, prompt: prompt) {
            launchedRunID = id
        } else if launcher.canStart {
            stop()
        } else {
            copyPrompt()
        }
    }

    /// The run AppLocalizer started, while this Autopilot run lasts.
    var launchedRun: ClaudeCodeRun? {
        guard run != nil else { return nil }
        return launcher?.run(launchedRunID)
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

    // MARK: - Prompt

    /// What to paste into the assistant to start.
    var prompt: String {
        guard let run else { return "" }
        let plan = run.plan
        let count = plan.localeCodes.count
        let languages = if count == 1 {
            String(localized: "1 language")
        } else if plan.includesNewLanguages {
            String(localized: "all \(count) languages the app supports")
        } else {
            String(localized: "all \(count) languages")
        }
        let screens = plan.displayTypes.contains(where: \.hasOwnScreens)
            ? String(localized: "every screen")
            : String(localized: "the \(plan.screens.count) screens")
        // The assistant picks the screens unless the person keeps theirs.
        let work = plan.choosesScreens
            ? String(localized: "decide which screens show \(app.name) best, build the app, capture them")
            : String(localized: "build the app, capture \(screens)")
        return String(localized: "Run \(app.name)’s screenshot plan from AppLocalizer: \(work) on \(plan.devicesTitle) in \(languages), and send the captures back.")
            + " " + String(localized: "Start with get_capture_plan for app \(app.id), then ask next_step after each step.")
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
        Task { await autopilot.resolveProblems(appID: appID, problemIDs: ids, with: resolution, context: context) }
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
        Task { await autopilot.usePicks(appID: appID, context: context) }
    }

    // MARK: - Choose

    func useDirection(_ direction: AutopilotDirection) {
        guard let autopilot else { return }
        let context = context
        viewedStep = nil
        let appID = app.id
        Task { await autopilot.useDirection(direction.id, appID: appID, context: context) }
    }

    /// Ask Claude Design: the note goes back to the design AI.
    func askForChanges() {
        autopilot?.requestRevision(revisionNote, appID: app.id)
        revisionNote = ""
        viewedStep = nil
    }

    /// The direction's five screenshots in the primary language, laid out
    /// with the picks.
    func layouts(for direction: AutopilotDirection) -> [ScreenshotLayout] {
        guard let run else { return [] }
        let key = "\(direction.id)@\(direction.receivedAt.timeIntervalSinceReferenceDate)"
        if let cached = directionLayouts[key] { return cached }
        let engine = ScreenshotLayoutEngine(catalog: screenshots.services.fonts)
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
        let key = "vision-\(direction.id)@\(direction.receivedAt.timeIntervalSinceReferenceDate)-\(capture?.id ?? "")"
        if let cached = directionLayouts[key]?.first { return (cached, capture) }
        let slot = screen.sourceScreenID.flatMap { run.plan.slot(of: $0) } ?? 0
        var template = direction.template
        template.slots = AutopilotLocalizer.slots(template.slots, count: run.plan.screens.count)
        let caption = screenshots.document?.captions.caption(locale: primaryLocale.code, slot: slot)
            ?? Self.caption(run.plan.caption(of: screen))
        let layout = ScreenshotLayoutEngine(catalog: screenshots.services.fonts).layout(
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
