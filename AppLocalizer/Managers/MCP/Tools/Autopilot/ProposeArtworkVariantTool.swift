//
//  ProposeArtworkVariantTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_artwork_variant`: the second header or search image for a
/// Product Page Optimization test, with one idea changed. AppLocalizer
/// renders it in every language with the real captures and checks it like
/// the first.
struct ProposeArtworkVariantTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_artwork_variant",
        title: "Send a Product Page Optimization variant",
        description: """
        When next_step says design_variant: the variant's look for that placement, as template fields and/or ops laid on \
        the current artwork's look (get_design_brief's extras describe the canvases), changing ONE idea only, the one \
        next_step names (by default the current image shows the interface doing the task, the variant the outcome or \
        feeling). Say the change in a sentence. When the idea is the words, pass texts [{locale, headline}] for every \
        language too. The phones still show the real picked captures. AppLocalizer renders and checks it in every \
        language; the person creates the test from Review & Push.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "template": ["type": "object", "description": "Template fields for the variant's look, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "change": MCPToolDefinition.string("The one idea changed, in a sentence."),
                "texts": [
                    "type": "array",
                    "items": ["type": "object", "properties": ["locale": ["type": "string"], "headline": ["type": "string"]]],
                    "description": "Only when the idea is the words: the variant's text per language.",
                ],
            ],
            required: ["appId", "run", "change"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        guard session.run.variantRequest != nil else {
            return .refused(String(localized: "No variant was asked for. Call next_step to see what AppLocalizer wants."), target: session.target)
        }
        guard let base = session.run.chosenDirection?.artworkLook else {
            return .refused(String(localized: "The run has no chosen direction to vary."), target: session.target)
        }
        var texts: [String: String] = [:]
        for item in try arguments.optionalArray("texts") ?? [] {
            guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale,
                  let headline = item["headline"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !headline.isEmpty
            else { continue }
            texts[locale.code] = headline
        }
        do {
            let look = try MCPDirectionTemplate.template(arguments, base: base, fonts: session.context.services.fonts)
            let variant = try await session.center.receiveVariant(
                appID: session.app.id, look: look, change: arguments.string("change"), texts: texts,
                client: context.clientName, context: session.context
            )
            let result: JSONValue = [
                "status": "rendered", "placement": .string(variant.role.rawValue), "languages": .int(variant.files.count),
                "next": "Nothing more: the person creates the test from Review & Push. Call next_step.",
            ]
            return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: session.target, outcome: .proposed)])
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
    }
}
