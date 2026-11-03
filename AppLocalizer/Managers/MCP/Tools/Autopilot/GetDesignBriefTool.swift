//
//  GetDesignBriefTool.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// `get_design_brief`: what the design AI needs to design the set — the
/// picks (with their images), every caption in every language with its
/// length, canvas sizes and safe areas, the longest caption per slot,
/// right-to-left languages and the brand source.
struct GetDesignBriefTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_design_brief",
        title: "Get the screenshot design brief",
        description: """
        The brief for designing the Autopilot run's screenshot set: the picked capture of each screen (images \
        attached), every caption in every language with its length, the longest caption per slot, canvas sizes \
        and safe areas per device, right-to-left languages, the design project to use, the starters you can \
        base a direction on, and the template fields you can set. When the run also makes product page header and \
        search results artwork or an App Preview, extras says which canvases and what each direction brings for \
        them. Design around the real captures; never draw the interface. Send each direction with propose_direction.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let run = session.run
        let services = session.context.services
        let document = try? await services.loadDocument(for: session.app, primaryLocale: session.context.primaryLocale)
        var picks: [JSONValue] = []
        var images: [MCPToolOutcome.ImageContent] = []
        for (slot, screen) in run.plan.screens.enumerated() {
            guard let capture = run.pickedCapture(for: screen.id) else { continue }
            picks.append([
                "slot": .int(slot + 1), "screen": .string(screen.id), "name": .string(screen.name),
                "pixelSize": .string(capture.pixelSize.title), "notes": .string(capture.notes),
            ])
            if let image = await services.captureImage(capture.screenshotCapture(slot: slot), for: session.app, pixelWidth: 360),
               let data = ScreenshotPNG.data(image)
            {
                images.append(.init(data: data, mimeType: "image/png"))
            }
        }
        var result: [String: JSONValue] = [
            "run": .string(run.id),
            "app": .string(session.app.name),
            "picks": .array(picks),
            "captions": .array(captions(run: run, document: document)),
            "canvases": .array(canvases(run: run, session: session)),
            "rightToLeft": .array(run.plan.localeCodes.filter { StoreLocaleCatalog.locale(code: $0)?.isRTL == true }.map(JSONValue.string)),
            "directions": .int(AutopilotRun.directionCount),
            "bases": .array(TemplateStarter.allCases.map {
                ["base": .string($0.rawValue), "style": .string($0.style.rawValue), "what": .string($0.summary)]
            }),
            "templateFields": .array(TemplateSchema.rules.keys.sorted().map(JSONValue.string)),
            "contract": """
            Send each direction as a template: the JSON get_template returns (any subset of its fields) and/or ops \
            {op: "replace", path, value} on a base starter. Fonts must be ones AppLocalizer has (system fonts, the \
            bundled gallery fonts, or uploaded); colors are hex. Per-slot looks go in slots[i].over (a whole bg, \
            device.tilt, device.dx/dy, deco…). Laurels and badges show a rating, so only use the app's real \
            App Store rating. Right-to-left languages mirror automatically.
            """,
        ]
        let app = session.app
        if let extras = run.mcpBriefExtras(referenceURL: { services.referenceURL($0, for: app) }) { result["extras"] = extras }
        if let project = session.center.designProject(for: session.app.id) {
            result["designProject"] = designProject(project)
        }
        if let revision = run.revision { result["revisionNote"] = .string(revision.note) }
        if !run.directions.isEmpty {
            result["directionsSoFar"] = .array(run.directions.map { ["id": .string($0.id), "name": .string($0.name)] })
        }
        session.center.noteBriefRead(appID: session.app.id, by: context.clientName)
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: session.target, outcome: .read)], images: images)
    }

    /// The connected design project, what was found in it, and what to do
    /// when it can't be opened from where the assistant runs (Claude Code
    /// that AppLocalizer started has only AppLocalizer's tools): design
    /// from the brief, never stop for it.
    private func designProject(_ project: DesignProject) -> JSONValue {
        var brand: [String: JSONValue] = [
            "kind": .string(project.kind.rawValue), "source": .string(project.link),
            "createDirectionsThere": .bool(project.createsInClaudeDesign),
            "ifYouCantOpenIt": """
            Don't stop: design the three directions from this brief (and the summary, when there is one), send each \
            with propose_direction, and skip creating them in the design project.
            """,
        ]
        if let summary = project.summary {
            var found: [String: JSONValue] = [
                "title": .string(summary.title),
                "colors": .array(summary.colors.map { ["name": .string($0.name), "hex": .string($0.hex)] }),
            ]
            if let typefaces = summary.typefaces { found["typefaces"] = .string(typefaces) }
            if let logo = summary.logo { found["logo"] = .string(logo) }
            if let voice = summary.voice { found["voice"] = .string(voice) }
            brand["summary"] = .object(found)
        } else {
            brand["readFirst"] = "Open the design project, then send what you found with report_design_source so the person sees it's the right one."
        }
        return .object(brand)
    }

    /// Each slot's captions per language with their length, and the longest.
    private func captions(run: AutopilotRun, document: ScreenshotsDocument?) -> [JSONValue] {
        run.plan.screens.enumerated().map { slot, screen in
            var perLocale: [JSONValue] = []
            var longest: (String, String)?
            for code in run.plan.localeCodes {
                var headline = document?.captions.caption(locale: code, slot: slot)?.headline ?? ""
                if headline.isEmpty, code == run.plan.primaryLocale { headline = screen.caption }
                guard !headline.isEmpty else { continue }
                perLocale.append(["locale": .string(code), "headline": .string(headline), "length": .int(headline.count)])
                if headline.count > (longest?.1.count ?? 0) { longest = (code, headline) }
            }
            var item: [String: JSONValue] = ["slot": .int(slot + 1), "screen": .string(screen.name), "captions": .array(perLocale)]
            if let longest { item["longest"] = ["locale": .string(longest.0), "headline": .string(longest.1), "length": .int(longest.1.count)] }
            return .object(item)
        }
    }

    /// Canvas size, orientation and safe area per device, from the base
    /// starter turned the way the device's captures are.
    private func canvases(run: AutopilotRun, session: MCPAutopilotSession) -> [JSONValue] {
        var template = ScreenshotTemplate.starter(.above, id: session.app.id, title: session.app.name, slotCount: max(run.plan.screens.count, 1))
        // Each device's canvas lies the way its captures do, as it will once used.
        template.canvas = AutopilotLocalizer.canvas(template.canvas, matching: run)
        let engine = ScreenshotLayoutEngine(catalog: session.context.services.fonts)
        // Apple Watch's screenshots are the captures themselves: nothing to design.
        // iPhone Duo has one for each pose the plan uses: the unfolded Duo's
        // and the folded phone's (its cover display framed on the same canvas).
        let items = run.plan.displayTypes.filter(\.hasCaptions).flatMap { display -> [(ScreenshotDisplayType, AutopilotDuoPose?)] in
            display == .iPhoneDuo
                ? Self.duoPoses(run.plan).map { (display, $0) }
                : [(display, nil)]
        }
        return items.map { display, pose in
            let cover = pose == .closed ? CaptureSizeRules.duoOuterSize : nil
            let layout = engine.layout(template, slot: 0, locale: session.context.primaryLocale, displayType: display, caption: nil, captureSize: cover)
            let safe = layout.safeArea
            var canvas: [String: JSONValue] = [
                "displayType": .string(display.mcpValue),
                "pixelSize": .string(layout.canvas.pixelSize.title),
                "orientation": .string(layout.canvas.isLandscape ? "landscape" : "portrait"),
                "safeArea": ["x": .int(Int(safe.minX)), "y": .int(Int(safe.minY)), "width": .int(Int(safe.width)), "height": .int(Int(safe.height))],
            ]
            if let pose {
                canvas["pose"] = .string(pose.rawValue)
                canvas["slots"] = .array(run.plan.duoSlots(pose).map { .int($0 + 1) })
                canvas["note"] = .string(Self.duoNote(pose, plan: run.plan))
            }
            if display == .visionPro {
                canvas["note"] = """
                AppLocalizer lays Apple Vision Pro out itself: the template's background and headline style, the headline centered at the \
                top, the capture in a floating window below. Design for iPhone and iPad.
                """
            }
            return .object(canvas)
        }
    }

    /// The poses that get a canvas of their own: a side-by-side image is
    /// one (the unfolded Duo's).
    static func duoPoses(_ plan: AutopilotPlan) -> [AutopilotDuoPose] {
        if plan.duoScreens == .both, plan.duoBoth == .sideBySide { return [.open] }
        return AutopilotDuoPose.allCases.filter { !plan.duoSlots($0).isEmpty }
    }

    /// What iPhone Duo's screenshots in `pose` look like, for the designer.
    static func duoNote(_ pose: AutopilotDuoPose, plan: AutopilotPlan) -> String {
        switch (plan.duoScreens, plan.duoBoth, pose) {
        case (.both, .sideBySide, _):
            "Each screenshot shows the unfolded Duo with the folded phone (its cover display, 1398 × 2034) beside it; AppLocalizer places both."
        case (_, _, .closed):
            "The folded phone on its cover display (1398 × 2034), framed on this canvas; every iPhone Duo screenshot is 2007 × 2853."
        case (_, _, .open):
            "The unfolded Duo's inner display, as Apple requires: 2007 × 2853."
        }
    }
}
