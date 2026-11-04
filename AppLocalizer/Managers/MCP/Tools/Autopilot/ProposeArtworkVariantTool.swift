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
        When next_step says design_variant: the variant for that placement, as html (the whole page, when next_step \
        gives the currentPage) or else as template fields and/or ops laid on the current artwork's look \
        (get_design_brief's extras describe the canvases), changing ONE idea only, the one \
        next_step names (by default the current image shows the interface doing the task, the variant the outcome or \
        feeling). Say the change in a sentence. When the idea is the words, pass texts [{locale, headline}] for every \
        language too, and for a page phrase (data-al="text") that isn't one of next_step's translatedPhrases, \
        phrases [{phrase, locale, text}] for every language but the primary one. The phones still show the real \
        picked captures. AppLocalizer renders and checks it in every \
        language; the person creates the test from Review & Push.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "run": MCPToolDefinition.string("The run's ID from get_capture_plan."),
                "html": MCPToolDefinition.string("The variant's whole page, when the current image is a page (next_step's currentPage)."),
                "template": ["type": "object", "description": "Template fields for the variant's look, as get_template returns them."],
                "ops": ["type": "array", "items": ["type": "object"], "description": "{op: \"replace\", path, value} changes."],
                "change": MCPToolDefinition.string("The one idea changed, in a sentence."),
                "texts": [
                    "type": "array",
                    "items": ["type": "object", "properties": ["locale": ["type": "string"], "headline": ["type": "string"]]],
                    "description": "Only when the idea is the words: the variant's text per language.",
                ],
                "phrases": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": ["phrase": ["type": "string"], "locale": ["type": "string"], "text": ["type": "string"]],
                    ],
                    "description": "A new page phrase's words in each other language: phrase as the page writes it in the primary language.",
                ],
            ],
            required: ["appId", "run", "change"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        guard let request = session.run.variantRequest else {
            return .refused(String(localized: "No variant was asked for. Call next_step to see what AppLocalizer wants."), target: session.target)
        }
        // A run with header concepts may have no direction: the live set's look, else a plain one.
        let live = session.run.usesConcepts
            ? try? await session.context.services.loadDocument(for: session.app, primaryLocale: session.context.primaryLocale).template
            : nil
        let look = session.run.usesConcepts
            ? session.run.artworkLook(live: live) ?? AutopilotCenter.fallbackLook(for: session.context)
            : session.run.chosenDirection?.artworkLook
        guard let base = look else {
            return .refused(String(localized: "The run has no chosen direction to vary."), target: session.target)
        }
        var texts: [String: String] = [:]
        for item in try arguments.optionalArray("texts") ?? [] {
            guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale,
                  let headline = item["headline"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !headline.isEmpty
            else { continue }
            texts[locale.code] = headline
        }
        let phrases = try Self.phrases(arguments, primary: session.run.plan.primaryLocale)
        var design: AutopilotArtworkDesign?
        var previews: [MCPArtworkPreview.Page] = []
        if let html = try arguments.optionalString("html") {
            guard html.utf8.count <= AutopilotArtworkDesign.maximumBytes else {
                return .refused(ArtworkWebError.tooLarge(html.utf8.count).localizedDescription, target: session.target)
            }
            let sent = AutopilotArtworkDesign(pages: [request.kind: html])
            let preview = MCPArtworkPreview(session: session, workspace: context.workspace)
            // Made after Localize: its phrases must already read in every language.
            var book = await preview.book()
            book.setPhrases(phrases, provenance: .assistant(client: context.clientName, date: session.center.now()))
            let checked = await preview.check(sent, book: book)
            if let refusal = checked.refusal { return .refused(refusal, target: session.target) }
            design = checked.design
            previews = checked.pages
        } else if session.run.madeArtworkDesign?.page(for: request.kind) != nil {
            return .refused(
                String(localized: "Send html: the variant’s whole \(request.kind.rawValue) page, next_step’s currentPage with one idea changed."),
                target: session.target
            )
        }
        do {
            let look = try MCPDirectionTemplate.template(arguments, base: base, fonts: session.context.services.fonts, allowsNothing: design != nil)
            let variant = try await session.center.receiveVariant(
                appID: session.app.id, look: look, design: design, change: arguments.string("change"), texts: texts, phrases: phrases,
                client: context.clientName, context: session.context
            )
            let result: JSONValue = [
                "status": "rendered", "placement": .string(variant.role.rawValue), "languages": .int(variant.files.count),
                "next": "Nothing more: the person creates the test from Review & Push. Call next_step.",
            ]
            return MCPToolOutcome(
                result: result, isError: false, logLines: [.init(target: session.target, outcome: .proposed)],
                images: previews.compactMap(MCPArtworkPreview.image)
            )
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
    }

    /// The `phrases` sent, phrase → locale → words, leaving out the primary
    /// language (the page's own words) and blank items.
    static func phrases(_ arguments: MCPToolArguments, primary: String) throws -> [String: [String: String]] {
        var phrases: [String: [String: String]] = [:]
        for item in try arguments.optionalArray("phrases") ?? [] {
            guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale, locale.code != primary,
                  case let phrase = ArtworkTextBook.phraseKey(item["phrase"]?.stringValue ?? ""), !phrase.isEmpty,
                  case let text = ArtworkTextBook.phraseKey(item["text"]?.stringValue ?? ""), !text.isEmpty
            else { continue }
            phrases[phrase, default: [:]][locale.code] = text
        }
        return phrases
    }
}
