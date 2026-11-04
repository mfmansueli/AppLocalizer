//
//  RenderArtworkTool.swift
//  AppLocalizer
//

import Foundation

/// `render_artwork`: a header or search page rendered by AppLocalizer in
/// one language, exactly as the artwork will be made, with its checks, so
/// Claude Design sees its page before proposing it.
struct RenderArtworkTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "render_artwork",
        title: "Render a header or search page",
        description: """
        Renders a header or search results page (get_design_brief's artworkDesign) the way AppLocalizer makes the \
        artwork: filled in for the language with the placement's text, the app's name, icon and the picked \
        captures, fitted, at the poster moment. Returns the image (960 px wide), where each data-al element landed, \
        how the text fits, every check, and what propose_direction would refuse. Pass html to try a page, or direction to see one already sent; locale \
        (default the primary language) and headline to try other words.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "kind": MCPToolDefinition.string("header, search or wide."),
                "html": MCPToolDefinition.string("The page to try."),
                "direction": MCPToolDefinition.string("A direction's id or name: its page for kind, when html isn't sent."),
                "concept": MCPToolDefinition.string("""
                A header concept's id or name: the page you're making for it (its own, or its loop's, when html isn't \
                sent). While Design waits for its pages, a page that passes shows on its row.
                """),
                "locale": MCPToolDefinition.string("A plan locale, e.g. de-DE; the primary one by default."),
                "headline": MCPToolDefinition.string("The words to try; the placement's own text by default."),
            ],
            required: ["appId", "kind"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        let plan = session.run.plan
        let name = try arguments.string("kind")
        guard let kind = AutopilotArtworkKind(rawValue: name), plan.artworkKinds.contains(kind) else {
            let kinds = plan.artworkKinds.map(\.rawValue).formatted(.list(type: .or))
            return .refused(
                plan.artworkKinds.isEmpty
                    ? String(localized: "This run makes no header or search artwork.")
                    : String(localized: "The run makes \(kinds), not “\(name)”."),
                target: session.target
            )
        }
        var html = try arguments.optionalString("html")
        let concept = try arguments.optionalString("concept").flatMap { session.run.concept($0) }
        if html == nil, let concept {
            html = (concept.motion ?? concept.design ?? concept.drafts)?.page(for: kind)
        }
        if html == nil, let wanted = try arguments.optionalString("direction") {
            let direction = session.run.directions.first { $0.id == wanted || $0.name.localizedCaseInsensitiveCompare(wanted) == .orderedSame }
            html = direction?.artworkDesign?.page(for: kind)
        }
        guard let html, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .refused(String(localized: "Send html, or a direction that has a \(kind.rawValue) page."), target: session.target)
        }
        let locale: StoreLocale
        if let code = try arguments.optionalString("locale") {
            guard let found = StoreLocaleCatalog.resolve(code).locale, plan.localeCodes.contains(found.code) else {
                return .refused(String(localized: "Use one of the plan’s locales: \(plan.localeCodes.joined(separator: ", "))."), target: session.target)
            }
            locale = found
        } else {
            locale = session.context.primaryLocale
        }
        let preview = MCPArtworkPreview(session: session, workspace: context.workspace)
        do {
            let page = try await preview.render(html: html, kind: kind, locale: locale, headline: arguments.optionalString("headline"))
            var result = MCPArtworkPreview.json(page)
            let words = MCPArtworkPreview.wordProblems(page.render.measure, kind: kind, locales: plan.localeCodes, primary: plan.primaryLocale)
            if !words.isEmpty, case var .object(object) = result {
                object["wouldBeRefused"] = .array(words.map { .string($0) })
                result = .object(object)
            }
            let checks = page.checks.map { "\($0.isError ? "Error" : "Advice"): \($0.text)" } + words
            session.center.logRender(
                (kind, locale.code), html: html, about: concept?.id, checks: checks, run: session.run, provider: context.clientName
            )
            // A page that passes shows on its concept's Design row meanwhile.
            if let concept, words.isEmpty, !page.checks.contains(where: \.isError) {
                session.center.noteConceptDraft(html, kind: kind, conceptID: concept.id, appID: session.app.id)
            }
            return MCPToolOutcome(
                result: result, isError: false, logLines: [.init(target: "\(session.target) · \(kind.title)", outcome: .read)],
                images: MCPArtworkPreview.image(page).map { [$0] } ?? []
            )
        } catch {
            return .failed(String(localized: "The page didn’t render: \(error.localizedDescription)"), target: session.target)
        }
    }
}
