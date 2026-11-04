//
//  ReviseDirectionTool.swift
//  AppLocalizer
//

import Foundation

/// `revise_direction`: a direction changed after the person's "Ask for
/// changes" note.
struct ReviseDirectionTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "revise_direction",
        title: "Revise a screenshot design direction",
        description: """
        Sends a revised direction after the person asked for changes (next_step gives the note and each \
        direction's current template and artwork look): the direction's id (or name) and its new template fields \
        and/or ops, laid on the direction as it is, and extrasTemplates for the header and search artwork (and the \
        App Preview) when the note is about them. Optionally a new rationale (what changed, and what the note asked \
        that AppLocalizer can't make) and sourceLink. Pass last: false on every direction but the final one; the \
        run goes back to the person to choose after the last.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "direction": MCPToolDefinition.string("The direction's id or name."),
                "template": ["type": "object", "description": "Template fields, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "rationale": MCPToolDefinition.string("What changed, in a sentence."),
                "sourceLink": MCPToolDefinition.string("Where to refine it."),
                "extrasTemplates": MCPDirectionTemplate.extrasSchema,
                "last": [
                    "type": "boolean",
                    "description": "False when another direction for the same note follows; true (the default) for the final one.",
                ],
            ],
            required: ["appId", "run", "direction"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let wanted = try arguments.string("direction")
        guard let direction = session.run.directions.first(where: { $0.id == wanted || $0.name.localizedCaseInsensitiveCompare(wanted) == .orderedSame }) else {
            let ids = session.run.directions.map { "\($0.id) (\($0.name))" }.formatted(.list(type: .or))
            return .refused(String(localized: "No direction “\(wanted)” in this run; it has \(ids)."), target: session.target)
        }
        do {
            let fonts = session.context.services.fonts
            let template = try MCPDirectionTemplate.template(arguments, base: direction.template, fonts: fonts)
            let extras = try MCPDirectionTemplate.extrasTemplates(
                arguments, over: template, bases: (direction.artworkTemplate, direction.previewTemplate), fonts: fonts
            )
            try await session.center.reviseDirection(
                direction.id, template: template, extras: extras, rationale: arguments.optionalString("rationale"),
                link: arguments.optionalString("sourceLink"), isLast: arguments.values["last"]?.boolValue ?? true,
                appID: session.app.id, context: session.context
            )
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        var result: [String: JSONValue] = ["status": "revised", "direction": .string(direction.id)]
        if session.run.plan.alsoMakes.makesArtwork {
            let sent = arguments.values["extrasTemplates"]?["artwork"] != nil
            result["artwork"] = .string(Self.artworkOutcome(sent: sent, ownLook: direction.artworkTemplate != nil))
        }
        if session.center.run(for: session.app.id)?.stage == .design {
            result["next"] = "Send the next direction for the same note; pass last: true (or leave it out) on the final one."
        }
        return MCPToolOutcome(
            result: .object(result), isError: false, logLines: [.init(target: "\(session.target) · \(direction.name)", outcome: .proposed)]
        )
    }

    /// What happened to the header and search artwork.
    static func artworkOutcome(sent: Bool, ownLook: Bool) -> String {
        if sent { return "The header and search artwork have the new look." }
        if ownLook {
            return "The header and search artwork kept their own look: only extrasTemplates.artwork changes them."
        }
        return "The header and search artwork follow the new template."
    }
}
