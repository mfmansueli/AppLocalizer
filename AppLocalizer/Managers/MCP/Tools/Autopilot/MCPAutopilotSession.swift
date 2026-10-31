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
    static func load(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPAutopilotSession {
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let services = context.workspace.services.screenshots
        guard let center = services.autopilot else {
            throw MCPToolError.unavailable(String(localized: "Screenshot Autopilot isn’t available here."))
        }
        guard let run = center.run(for: app.id), run.stage != .plan else {
            throw MCPToolError.notFound(String(localized: "\(app.name) has no Autopilot run waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… and press Start Autopilot."))
        }
        if let wanted = try arguments.optionalString("run"), !wanted.isEmpty, wanted != run.id {
            throw MCPToolError.notFound(String(localized: "Run “\(wanted)” is over; \(app.name)’s current run is “\(run.id)”. Call get_capture_plan."))
        }
        let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)
            ?? app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? .englishUS
        return MCPAutopilotSession(app: app, center: center, context: AutopilotContext(app: app, services: services, primaryLocale: primary), run: run)
    }

    /// Reads the run again after a change.
    mutating func refresh() {
        if let current = center.run(for: app.id) { run = current }
    }

    /// "Lumen Journal · Autopilot".
    var target: String { String(localized: "\(app.name) · Autopilot") }

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
        return AutopilotCaptureTarget(screenID: screen.id, displayType: display, locale: locale.code)
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
