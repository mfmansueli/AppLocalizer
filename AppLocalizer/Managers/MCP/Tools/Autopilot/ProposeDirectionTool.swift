//
//  ProposeDirectionTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_direction`: one design direction for the Autopilot run, as an
/// AppLocalizer template. Directions arrive one by one; the person
/// chooses.
struct ProposeDirectionTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_direction",
        title: "Propose a screenshot design direction",
        description: """
        Sends one design direction for the Autopilot run: a name ("Quiet Indigo"), a one-sentence rationale, \
        and the screenshots' template — the JSON get_template returns (any subset of its fields) and/or ops on \
        dotted paths — laid on a base starter (above, band or panorama). When the run also makes header and search \
        artwork, artworkDesign carries them: one HTML page per canvas that you design completely \
        (get_design_brief's artworkDesign says how); AppLocalizer renders each in the primary language, checks it \
        and returns the images, so look at them. When the person said what they expect (artworkDesign.askedByThePerson), \
        the images must show it, and followsTheRequest says how. extrasTemplates.appPreview can give the App Preview's captions a \
        look of their own. When the run makes no screenshots (get_design_brief's noScreenshots), leave base, template \
        and ops out unless they style its App Preview. Refused, with what failed, for unknown template fields, values out of range, fonts that \
        can't draw a language, a missing page, a page that doesn't render or breaks Apple's rules, words written \
        outside data-al (they'd read the same in every language), or a missing followsTheRequest. Pass \
        sourceLink to the direction in the design project so the person can open it there.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "name": MCPToolDefinition.string("The direction's name, e.g. Quiet Indigo."),
                "rationale": MCPToolDefinition.string("Why, in a sentence the person reads."),
                "base": MCPToolDefinition.string("above, band or panorama."),
                "template": ["type": "object", "description": "Template fields, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "sourceLink": MCPToolDefinition.string("Where to refine it, e.g. the Claude Design project's link."),
                "artworkDesign": AutopilotArtworkDesign.mcpSchema,
                "followsTheRequest": MCPToolDefinition.string("""
                Required when get_design_brief has artworkDesign.askedByThePerson: in a sentence, what in this direction's \
                header and search shows what the person asked (e.g. "three of their motivational phrases on the header, \
                one on search").
                """),
                "extrasTemplates": MCPDirectionTemplate.extrasSchema,
            ],
            required: ["appId", "run", "name", "rationale"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let base = try MCPDirectionTemplate.starter(arguments, app: session.app, slotCount: max(session.run.plan.screens.count, 1))
        let template: ScreenshotTemplate
        let extras: (artwork: ScreenshotTemplate?, preview: ScreenshotTemplate?)
        let design: AutopilotArtworkDesign?
        let kinds = session.run.plan.artworkKinds
        do {
            // Without screenshots, nothing uses a template unless the App Preview does.
            template = try MCPDirectionTemplate.template(
                arguments, base: base, fonts: session.context.services.fonts, allowsNothing: !session.run.plan.makesScreenshots
            )
            extras = try MCPDirectionTemplate.extrasTemplates(arguments, over: template, fonts: session.context.services.fonts)
            design = try AutopilotArtworkDesign.mcpPages(arguments, kinds: kinds)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        let asked = session.run.plan.alsoMakes.artworkDirection
        let follows = try arguments.optionalString("followsTheRequest")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !kinds.isEmpty, !asked.isEmpty, follows.isEmpty {
            return .refused(Self.askedRefusal(asked), target: session.target)
        }
        let missing = (design ?? AutopilotArtworkDesign()).missing(kinds)
        if !missing.isEmpty {
            let names = missing.map(\.rawValue).formatted(.list(type: .and))
            return .refused(
                String(localized: "Send artworkDesign with a page for \(names): you design the header and search images yourself, as get_design_brief’s artworkDesign says."),
                target: session.target
            )
        }
        var previews: [MCPArtworkPreview.Page] = []
        var checkedDesign = design
        if let design {
            let checked = await MCPArtworkPreview(session: session, workspace: context.workspace).check(design, screenshots: template)
            if let refusal = checked.refusal { return .refused(refusal, target: session.target) }
            previews = checked.pages
            checkedDesign = checked.design
        }
        let name = try arguments.string("name")
        let direction = try AutopilotDirection(
            id: "d-" + session.center.makeID().prefix(8), name: name, rationale: arguments.string("rationale"),
            source: session.run.designKind == .none ? .claudeDesign : session.run.designKind, client: context.clientName,
            template: template, artworkTemplate: extras.artwork, artworkDesign: checkedDesign, previewTemplate: extras.preview,
            link: arguments.optionalString("sourceLink"), receivedAt: session.center.now()
        )
        do {
            try await session.center.addDirection(direction, appID: session.app.id, context: session.context)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        session.refresh()
        let stored = session.run.directions.first { $0.id == direction.id }
        var result: [String: JSONValue] = [
            "status": "received",
            "direction": .string(direction.id),
            "received": .int(session.run.directions.count),
            "of": .int(AutopilotRun.directionCount),
            "checks": .array((stored?.checks ?? []).map { .string($0.title) }),
        ]
        if !previews.isEmpty {
            result["artwork"] = .array(previews.map(MCPArtworkPreview.json))
            result["artworkImages"] = """
            Attached in the same order, in the primary language: look at them and send a better page with \
            revise_direction only if the person asks for changes.
            """
        }
        if !follows.isEmpty { result["followsTheRequest"] = .string(follows) }
        return MCPToolOutcome(
            result: .object(result), isError: false, logLines: [.init(target: "\(session.target) · \(name)", outcome: .proposed)],
            images: previews.compactMap(MCPArtworkPreview.image)
        )
    }

    /// Why a direction without followsTheRequest is refused: what the
    /// person asked, so the designer answers it.
    static func askedRefusal(_ asked: AutopilotArtworkDirection) -> String {
        let words = asked.trimmedText.isEmpty ? String(localized: "the references they attached") : "“\(asked.trimmedText)”"
        return String(localized: """
        The person said what they expect of the header and search: \(words). Make sure this direction's pages show it, \
        then send followsTheRequest: in a sentence, what in them answers it.
        """)
    }
}
