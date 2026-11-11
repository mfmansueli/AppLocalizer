//
//  MCPAutopilotSession.swift
//  AppLocalizer
//

import Foundation

/// An Autopilot tool's app, its run and the center that keeps it.
@MainActor
struct MCPAutopilotSession {
    let app: StoreApp
    let center: AutopilotCenter
    let context: AutopilotContext
    var run: AutopilotRun

    /// The app's current run; `run` in the arguments, when given, must be
    /// it.
    /// `atPlan`: a tool the plan uses before the run starts (Suggest
    /// Screens).
    static func load(_ arguments: MCPToolArguments, in context: MCPToolContext, atPlan: Bool = false) async throws -> MCPAutopilotSession {
        let (app, center) = try await center(arguments, in: context)
        guard let run = center.run(for: app.id), run.stage != .plan || atPlan else {
            throw MCPToolError.notFound(String(localized: "\(app.name) has no Autopilot run waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… and press Start Autopilot."))
        }
        if let wanted = try arguments.optionalString("run"), !wanted.isEmpty, wanted != run.id {
            throw MCPToolError.notFound(String(localized: "Run “\(wanted)” is over; \(app.name)’s current run is “\(run.id)”. Call get_capture_plan."))
        }
        return MCPAutopilotSession(app: app, center: center, context: Self.context(app: app, run: run, in: context), run: run)
    }

    /// The app a tool is about and the center that keeps its runs, whether
    /// it has a run or not: the plan's proposals don't need one.
    static func center(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> (app: StoreApp, center: AutopilotCenter) {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        guard let center = context.workspace.services.screenshots.autopilot else {
            throw MCPToolError.unavailable(String(localized: "Screenshot Autopilot isn’t available here."))
        }
        return (app, center)
    }

    /// "Lumen Journal · Autopilot".
    static func target(_ app: StoreApp) -> String {
        String(localized: "\(app.name) · Autopilot")
    }

    /// What a run touches the app's screenshots with, in its primary
    /// language.
    static func context(app: StoreApp, run: AutopilotRun, in context: MCPToolContext) -> AutopilotContext {
        let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)
            ?? app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? .englishUS
        return AutopilotContext(app: app, services: context.workspace.services.screenshots, primaryLocale: primary)
    }

    /// Reads the run again after a change.
    mutating func refresh() {
        if let current = center.run(for: app.id) { run = current }
    }

    /// "Lumen Journal · Autopilot".
    var target: String { Self.target(app) }

    /// "Lumen Journal · Today · de-DE · iPhone 6.9″".
    func target(_ capture: AutopilotCaptureTarget) -> String {
        let name = run.plan.screen(id: capture.screenID)?.name ?? capture.screenID
        return "\(app.name) · \(name) · \(capture.locale) · \(capture.displayType.title)"
    }

    /// The screen, device and language a capture or problem is about.
    func captureTarget(_ arguments: MCPToolArguments) throws -> AutopilotCaptureTarget {
        let screen = try screen(arguments.string("screen"))
        let display = try arguments.optionalString("displayType").map { value in
            guard let display = ScreenshotDisplayType(mcpValue: value), run.plan.displayTypes.contains(display) else {
                let devices = run.plan.displayTypes.map(\.mcpValue).formatted(.list(type: .or))
                throw MCPToolError.invalidArgument(name: "displayType", expected: String(localized: "one of the plan’s devices: \(devices)"))
            }
            return display
        } ?? .iPhone
        let code = try arguments.string("locale")
        guard let locale = StoreLocaleCatalog.resolve(code).locale, run.plan.localeCodes.contains(locale.code) else {
            throw MCPToolError.invalidArgument(name: "locale", expected: String(localized: "one of the plan’s locales: \(run.plan.localeCodes.joined(separator: ", "))"))
        }
        var target = AutopilotCaptureTarget(screenID: screen.id, displayType: display, locale: locale.code)
        if display == .iPhoneDuo {
            // iPhone Duo's open or closed: as sent, else the one the run is
            // capturing now (the closed ones come first), else the screen's
            // first; a capture with both is placed by its size when it
            // arrives. Alba's "Duo open while the closed screenshots are
            // due" came without a pose and was filed under the open one.
            let poses = run.plan.slot(of: screen.id).map(run.plan.duoPoses(forSlot:)) ?? []
            let sent = try arguments.optionalString("pose").flatMap(AutopilotDuoPose.init(rawValue:))
            let now = run.duoPoseWanted.flatMap { poses.contains($0) ? $0 : nil }
            target.duoPose = sent.flatMap { poses.contains($0) ? $0 : nil } ?? now ?? poses.first
        }
        return target
    }

    /// A screen by its ID, its name or its slot number.
    func screen(_ value: String) throws -> AutopilotScreen {
        let plan = run.plan
        if let screen = plan.screen(id: value) { return screen }
        if let screen = plan.screens.first(where: { $0.name.localizedCaseInsensitiveCompare(value) == .orderedSame }) { return screen }
        if let number = Int(value), plan.screens.indices.contains(number - 1) { return plan.screens[number - 1] }
        let ids = plan.screens.map(\.id).joined(separator: ", ")
        throw MCPToolError.invalidArgument(name: "screen", expected: String(localized: "a screen ID from the plan: \(ids)"))
    }
}
