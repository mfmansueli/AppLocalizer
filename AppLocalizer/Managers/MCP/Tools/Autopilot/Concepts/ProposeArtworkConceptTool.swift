//
//  ProposeArtworkConceptTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_artwork_concept`: one header and search concept, apart from
/// the screenshot directions. Its idea first (as the concepts prompt wrote
/// it), and its pages with it or after (the pages prompt), each rendered
/// and checked like propose_direction's.
struct ProposeArtworkConceptTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_artwork_concept",
        title: "Propose a header and search concept",
        description: """
        Sends one header and search concept for the Autopilot run, apart from the screenshot directions (next_step's \
        design action hands you the prompts). concept is one item of the concepts prompt's answer, as you wrote it; send \
        each as soon as it's written, and the person sees it on the Design step. artworkDesign carries its pages, one \
        self-contained HTML page per canvas (the pages prompt): send them with the concept, or later with the same \
        concept id. AppLocalizer renders each in the primary language and checks it like propose_direction, and returns \
        the images. Refused, with what to fix, for a template the person didn't pick or another concept took, a kind \
        another concept has (going freely), a missing follows_the_request when the person asked for something, text \
        besides the name and phrases, or a page that doesn't render or breaks Apple's rules.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "concept": AutopilotArtworkConcept.mcpSchema,
                "artworkDesign": AutopilotArtworkDesign.mcpSchema,
                "followsTheRequest": MCPToolDefinition.string("""
                How the concept follows what the person asked (get_design_brief's artworkDesign.askedByThePerson); the \
                concept's follows_the_request works too.
                """),
                "recommended": ["type": "boolean", "description": "True on the concept your answer recommends."],
            ],
            required: ["appId", "run", "concept"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var session = try await MCPAutopilotSession.load(arguments, in: context)
        let run = session.run
        guard run.usesConcepts else {
            let why = run.plan.artworkKinds.isEmpty
                ? String(localized: "This run makes no header or search artwork.")
                : String(localized: "This run started before header concepts: send the header and search with propose_direction’s artworkDesign.")
            return .refused(why, target: session.target)
        }
        let concept: AutopilotArtworkConcept
        var design: AutopilotArtworkDesign?
        do {
            concept = try AutopilotArtworkConcept.mcp(
                arguments.values["concept"], follows: arguments.optionalString("followsTheRequest"),
                recommended: arguments.optionalBool("recommended"), run: run, client: context.clientName, at: session.center.now()
            )
            design = try AutopilotArtworkDesign.mcpPages(arguments, kinds: run.plan.artworkKinds)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        var previews: [MCPArtworkPreview.Page] = []
        var sent = concept
        if let design {
            let checked = await MCPArtworkPreview(session: session, workspace: context.workspace).check(design, requiresHeadline: false)
            if let refusal = checked.refusal {
                session.center.logAnswer("propose_artwork_concept", concept: concept, pages: design, checks: [refusal], run: run, provider: context.clientName)
                return .refused(refusal, target: session.target)
            }
            previews = checked.pages
            sent.design = checked.design
        }
        let stored: AutopilotArtworkConcept
        do {
            stored = try await session.center.addConcept(sent, appID: session.app.id, context: session.context)
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        session.center.logAnswer(
            "propose_artwork_concept", concept: stored, pages: design, checks: previews.flatMap(\.checks).map(\.text), run: run,
            provider: context.clientName
        )
        session.refresh()
        let now = session.run
        let missing = (stored.design ?? AutopilotArtworkDesign()).missing(now.plan.artworkKinds)
        var result: [String: JSONValue] = [
            "status": "received",
            "concept": .string(stored.id),
            "received": .int(now.conceptList.count),
            "designed": .int(now.designedConcepts.count),
            "of": .int(now.expectedConcepts),
        ]
        if !missing.isEmpty {
            result["next"] = .string(String(localized: """
            Make its pages with the pages prompt and send them with propose_artwork_concept, concept {"id": "\(stored.id)"} and \
            artworkDesign: \(missing.map(\.rawValue).formatted(.list(type: .and))) still to come.
            """))
        }
        if !previews.isEmpty {
            result["artwork"] = .array(previews.map(MCPArtworkPreview.json))
            result["artworkImages"] = "Attached in the same order, in the primary language: look at them."
        }
        return MCPToolOutcome(
            result: .object(result), isError: false, logLines: [.init(target: "\(session.target) · \(stored.name)", outcome: .proposed)],
            images: previews.compactMap(MCPArtworkPreview.image)
        )
    }
}
