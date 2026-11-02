//
//  StudioDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Board 21's states, in Lumen Journal's Screenshots section:
///
/// - `st-home`, `st-live-ar`, `st-noasst`, `st-design`: the preview with
///   Autopilot idle (Arabic falling back to English; no assistant; Connect
///   a Design Project open).
/// - `st-plan`, `st-wait`, `st-cap`, `st-fail`, `st-pick`, `st-des`,
///   `st-choose`, `st-choose-rev`, `st-nodesign`, `st-loc`,
///   `st-ready-sheet`: the Autopilot sheet at each stage.
/// - `st-refused`: capturing, with a command the session wasn't allowed
///   to run.
/// - `st-group`: capturing, with one change to the project stopping the
///   same screen in two languages on iPhone and iPad (one card).
/// - `st-device`: capturing, with no iPhone Duo simulator on this Mac (one
///   card for the device, which installs it).
/// - `st-duo-closed`: capturing, with iPhone Duo's simulator made, running
///   and closed (its card opens Device Hub and says the run goes on once
///   it's open); `st-duo-opens`: the pretend person opens it a moment
///   later and the run tries it again; `st-duo-stuck`: its SpringBoard
///   crashed, so AppLocalizer restarts it; `st-duo-old`: the helper is from
///   before it could look at the Duo (the assistant's fix and how to
///   restart it by hand); `st-plan-duo`: the Plan on a Mac with that
///   simulator closed.
/// - `st-stalled`: capturing, with nothing arriving for over an hour (the
///   prompt was pasted): Continue copies the prompt that picks it up.
/// - `st-cap-page`, `st-pick-page`: the strip while it runs or waits.
/// - `st-ready`, `st-ready-de`, `st-ready-ar`, `st-ready-ipad`: the new set
///   in the preview (German in Dark, Arabic, iPad).
/// - Every device the app supports, with Polish, Turkish and Hebrew not on
///   the App Store yet: `st-plan-all`, `st-cap-watch`, `st-cap-vision`,
///   `st-pick-all`, `st-choose-all`, `st-loc-all`, `st-ready-sheet-all` in
///   the sheet; `st-live-watch`, `st-live-vision`, `st-ready-watch`,
///   `st-ready-vision` in the preview.
/// - `st-asc-watch`: no project report, but the version's build on App
///   Store Connect has an Apple Watch app.
/// - `st-plan-link`: the Plan with a Claude Design link nobody has read
///   yet and a screen name too long for its column.
enum StudioDebugScenes {
    static let ids: [String] = [
        "st-home", "st-live-ar", "st-noasst", "st-design", "st-plan", "st-wait", "st-cap", "st-fail", "st-refused", "st-group", "st-device",
        "st-duo-closed", "st-duo-opens", "st-duo-stuck", "st-duo-old", "st-plan-duo", "st-stalled", "st-cap-page",
        "st-pick", "st-pick-page", "st-des", "st-choose", "st-choose-rev", "st-nodesign", "st-loc", "st-ready-sheet",
        "st-ready", "st-ready-de", "st-ready-ar", "st-ready-ipad", "st-asc-watch", "st-plan-link",
    ] + everyDeviceIDs

    static let everyDeviceIDs = [
        "st-plan-all", "st-cap-watch", "st-cap-vision", "st-pick-all", "st-choose-all", "st-loc-all", "st-ready-sheet-all",
        "st-live-watch", "st-live-vision", "st-ready-watch", "st-ready-vision",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        if let run = everyDeviceSheetRun(for: id) {
            // A Mac that runs every device, so capturing on them is real.
            DebugSimulators.runEveryDevice()
            return scene(run: run, sheet: true, everyDevice: true)
        }
        if let run = duoRun(for: id) {
            return scene(run: run, project: StudioDebugRuns.northpier, sheet: true)
        }
        if id == "st-plan-link" {
            return scene(run: StudioDebugRuns.linkedPlan, project: StudioDebugRuns.unreadLink, sheet: true)
        }
        if let run = sheetRun(for: id) {
            return scene(run: run, project: id == "st-nodesign" ? nil : StudioDebugRuns.northpier, sheet: true) { model in
                if id == "st-wait" { model.studio.didCopyPrompt = true }
            }
        }
        return pageScene(for: id)
    }

    /// The iPhone Duo scenes' run, after setting up the pretend Duo.
    @MainActor
    private static func duoRun(for id: String) -> AutopilotRun? {
        switch id {
        case "st-duo-closed":
            DebugSimulators.runDuo(booted: true)
            return StudioDebugRuns.closedDuo
        case "st-duo-opens":
            DebugSimulators.runDuo(booted: true, opensAfterLooks: 6)
            return StudioDebugRuns.closedDuo
        case "st-duo-stuck":
            DebugSimulators.runDuo(booted: true, inner: .spinner, crashed: true)
            return StudioDebugRuns.stuckDuo
        case "st-duo-old":
            DebugSimulators.runDuo(booted: true, olderHelper: true)
            return StudioDebugRuns.closedDuo
        case "st-plan-duo":
            DebugSimulators.runDuo(booted: true)
            return StudioDebugRuns.run(.plan)
        default:
            return nil
        }
    }

    /// The every-device scenes that open the Autopilot sheet.
    @MainActor
    private static func everyDeviceSheetRun(for id: String) -> AutopilotRun? {
        switch id {
        case "st-plan-all": StudioDebugRuns.run(.plan, everyDevice: true)
        case "st-cap-watch":
            StudioDebugRuns.capturing(upTo: AutopilotCaptureTarget(screenID: "watch-week", displayType: .watch, locale: "de-DE"))
        case "st-cap-vision":
            StudioDebugRuns.capturing(upTo: AutopilotCaptureTarget(screenID: "vision-search", displayType: .visionPro, locale: "en-US"))
        case "st-pick-all": StudioDebugRuns.run(.pick, everyDevice: true)
        case "st-choose-all": StudioDebugRuns.run(.choose, everyDevice: true)
        case "st-loc-all": StudioDebugRuns.run(.localize, everyDevice: true)
        case "st-ready-sheet-all": StudioDebugRuns.run(.ready, everyDevice: true)
        default: nil
        }
    }

    /// The scenes that open the Autopilot sheet, and the run each shows.
    @MainActor
    private static func sheetRun(for id: String) -> AutopilotRun? {
        let stages: [String: AutopilotStage] = [
            "st-plan": .plan, "st-wait": .waiting, "st-cap": .capture, "st-pick": .pick, "st-des": .design,
            "st-choose": .choose, "st-loc": .localize, "st-ready-sheet": .ready,
        ]
        if let stage = stages[id] { return StudioDebugRuns.run(stage) }
        switch id {
        case "st-fail": return StudioDebugRuns.failing
        case "st-refused": return StudioDebugRuns.refused
        case "st-group": return StudioDebugRuns.grouped
        case "st-device": return StudioDebugRuns.noDuoSimulator
        case "st-stalled": return StudioDebugRuns.stalled
        case "st-choose-rev": return StudioDebugRuns.revised
        case "st-nodesign": return StudioDebugRuns.run(.choose, design: false)
        default: return nil
        }
    }

    @MainActor
    private static func pageScene(for id: String) -> AnyView? {
        switch id {
        case "st-home": scene()
        case "st-live-ar": scene { $0.studio.localeCode = "ar-SA" }
        case "st-noasst": scene(assistants: .off)
        case "st-design": scene(project: nil) { $0.studio.isDesignProjectPresented = true }
        case "st-cap-page": scene(run: StudioDebugRuns.failing)
        case "st-pick-page": scene(run: StudioDebugRuns.run(.pick))
        case "st-live-watch": scene(everyDevice: true) { $0.studio.device = .watch }
        case "st-live-vision": scene(everyDevice: true) { $0.studio.device = .visionPro }
        case "st-asc-watch": scene(buildHasWatchApp: true)
        default: readyScene(for: id)
        }
    }

    /// The page once the run is Ready, on the new set.
    @MainActor
    private static func readyScene(for id: String) -> AnyView? {
        switch id {
        case "st-ready": ready()
        case "st-ready-de": ready { model in
                model.studio.localeCode = "de-DE"
                model.studio.appearance = .dark
            }
        case "st-ready-ar": ready { $0.studio.localeCode = "ar-SA" }
        case "st-ready-ipad": ready { $0.displayType = .iPad }
        case "st-ready-watch": ready(everyDevice: true) { $0.studio.device = .watch }
        case "st-ready-vision": ready(everyDevice: true) { $0.studio.device = .visionPro }
        default: nil
        }
    }

    @MainActor
    private static func ready(everyDevice: Bool = false, _ setUp: (@MainActor (ScreenshotsViewModel) -> Void)? = nil) -> AnyView {
        scene(run: StudioDebugRuns.run(.ready, everyDevice: everyDevice), everyDevice: everyDevice) { model in
            model.studio.choice = .new
            setUp?(model)
        }
    }

    @MainActor
    private static func scene(
        run: AutopilotRun? = nil,
        project: DesignProject? = StudioDebugRuns.northpier,
        sheet: Bool = false,
        assistants: AssistantsDebugState = .paired,
        everyDevice: Bool = false,
        buildHasWatchApp: Bool = false,
        setUp: (@MainActor (ScreenshotsViewModel) -> Void)? = nil
    ) -> AnyView {
        let center = AutopilotCenter()
        center.holdsStages = true
        center.now = { StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 32) }
        if let project { center.setDesignProject(project, for: StudioDebugRuns.appID) }
        if let run { center.install(run) }
        let screenshots = DebugScreenshotsServices(scenario: everyDevice ? .everyDevice : .standard, opening: ScreenshotsDebugOpening { model in
            setUp?(model)
            model.studio.isAutopilotPresented = sheet
        })
        screenshots.initialTab = .preview
        screenshots.autopilot = center
        var storePage = DebugStorePageServices()
        storePage.buildHasWatchApp = buildHasWatchApp
        if everyDevice {
            let support = DebugAppSupport.center()
            screenshots.appSupport = support
            storePage.appSupport = support
        }
        storePage.screenshots = screenshots
        var services = WorkspaceServices.debug
        services.storePage = storePage
        let main = DebugMainScene(services: services, section: .screenshots, pendingChanges: DebugWorkspace.pendingChanges)
        return AnyView(main.modifier(StudioDebugAssistants(state: assistants)))
    }
}
#endif
