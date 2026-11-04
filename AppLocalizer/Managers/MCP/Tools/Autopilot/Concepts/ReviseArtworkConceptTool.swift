//
//  ReviseArtworkConceptTool.swift
//  AppLocalizer
//

import Foundation

/// `revise_artwork_concept`: a concept's new pages. At Choose's "Ask for
/// changes", the concepts the note is for; after Localize and check, the
/// chosen header's animated pages (the motion prompt), and at Watch the
/// header loop, its new version for the person's note.
struct ReviseArtworkConceptTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "revise_artwork_concept",
        title: "Revise a header and search concept",
        description: """
        Sends a concept's new pages. When next_step says revise (the person's note on concepts), send each concept the \
        note is for, with artworkDesign holding the pages that change (whole pages; the others stay) and change_notes \
        saying what changed; pass last: false on every one but the final. When next_step says animate_header or \
        revise_loop, send the chosen concept's animated pages (every canvas) the same way: AppLocalizer checks that \
        every animation repeats evenly in the loop, frame 0 is the still, the last frame leads back to it, the data-al \
        elements never move and no frame jumps, then makes the loops. Rendered and checked like propose_artwork_concept.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "concept_id": MCPToolDefinition.string("The concept's id (\"A\") or name."),
                "artworkDesign": AutopilotArtworkDesign.mcpSchema,
                "change_notes": MCPToolDefinition.string("What changed, in plain words, for the person to read."),
                "last": [
                    "type": "boolean",
                    "description": "False when another concept for the same note follows; true (the default) for the final one.",
                ],
            ],
            required: ["appId", "run", "concept_id"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let run = session.run
        let wanted = try arguments.string("concept_id")
        guard run.usesConcepts, let concept = run.concept(wanted) else {
            let ids = run.conceptList.map { "\($0.id) (\($0.name))" }.formatted(.list(type: .or))
            return .refused(
                run.usesConcepts
                    ? String(localized: "No concept “\(wanted)” in this run; it has \(ids).")
                    : String(localized: "This run has no header concepts: revise the direction with revise_direction."),
                target: session.target
            )
        }
        let design: AutopilotArtworkDesign?
        do {
            design = try AutopilotArtworkDesign.mcpPages(arguments, kinds: run.plan.artworkKinds)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        let notes = try arguments.optionalString("change_notes")
        if run.stage == .localize || run.stage == .watchPreview {
            return await animate(concept, design: design, notes: notes, session: session, context: context)
        }
        var previews: [MCPArtworkPreview.Page] = []
        var checkedDesign = design
        if let design {
            let checked = await MCPArtworkPreview(session: session, workspace: context.workspace).check(design, requiresHeadline: false)
            if let refusal = checked.refusal {
                session.center.logAnswer("revise_artwork_concept", concept: concept, pages: design, checks: [refusal], run: run, provider: context.clientName)
                return .refused(refusal, target: session.target)
            }
            previews = checked.pages
            checkedDesign = checked.design
        }
        do {
            try session.center.reviseConcept(
                concept.id, design: checkedDesign, changeNotes: notes, isLast: arguments.values["last"]?.boolValue ?? true, appID: session.app.id
            )
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        session.center.logAnswer(
            "revise_artwork_concept", concept: concept, pages: design, checks: previews.flatMap(\.checks).map(\.text), run: run,
            provider: context.clientName
        )
        var result: [String: JSONValue] = ["status": "revised", "concept": .string(concept.id)]
        if session.center.run(for: session.app.id)?.stage == .design {
            result["next"] = "Send the next concept or direction for the same note; pass last: true (or leave it out) on the final one."
        }
        if !previews.isEmpty { result["artwork"] = .array(previews.map(MCPArtworkPreview.json)) }
        return MCPToolOutcome(
            result: .object(result), isError: false, logLines: [.init(target: "\(session.target) · \(concept.name)", outcome: .proposed)],
            images: previews.compactMap(MCPArtworkPreview.image)
        )
    }

    /// The chosen header's animated pages, checked for motion, then the
    /// loops are made with them.
    private func animate(
        _ concept: AutopilotArtworkConcept, design: AutopilotArtworkDesign?, notes: String?, session: MCPAutopilotSession, context: MCPToolContext
    ) async -> MCPToolOutcome {
        let run = session.run
        guard let design else {
            return .refused(String(localized: "Send artworkDesign with the animated pages, one per canvas."), target: session.target)
        }
        let preview = MCPArtworkPreview(session: session, workspace: context.workspace)
        let checked = await preview.check(design, requiresHeadline: false)
        if let refusal = checked.refusal {
            session.center.logAnswer("revise_artwork_concept", concept: concept, pages: design, checks: [refusal], run: run, provider: context.clientName)
            return .refused(refusal, target: session.target)
        }
        let moving = Dictionary(checked.pages.map { ($0.kind, $0.render.moving.map(\.rawValue)) }) { $1 }
        let pages = checked.design.laid(over: concept.motion ?? concept.design)
        let problems = await preview.motionProblems(pages, still: concept.design, moving: moving)
        session.center.logAnswer("revise_artwork_concept", concept: concept, pages: design, checks: problems, run: run, provider: context.clientName)
        if session.center.refusesMotion(problems, appID: session.app.id) {
            let fix = problems.joined(separator: " ")
            return .refused(String(localized: "\(fix) Fix it and send the animated pages again."), target: session.target)
        }
        do {
            try await session.center.addLoop(
                concept.id, design: checked.design, changeNotes: notes, client: context.clientName, appID: session.app.id,
                context: session.context
            )
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        var result: [String: JSONValue] = [
            "status": "animated", "concept": .string(concept.id),
            "next": "AppLocalizer makes the loops in every language now; call next_step.",
        ]
        if !problems.isEmpty { result["warnings"] = .array(problems.map { .string($0) }) }
        result["artwork"] = .array(checked.pages.map(MCPArtworkPreview.json))
        return MCPToolOutcome(
            result: .object(result), isError: false, logLines: [.init(target: "\(session.target) · \(concept.name) loop", outcome: .proposed)],
            images: checked.pages.compactMap(MCPArtworkPreview.image)
        )
    }
}
