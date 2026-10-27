//
//  GetCaptionsTool.swift
//  AppLocalizer
//

import Foundation

/// `get_captions`: per locale and slot, the caption, who wrote it, and how
/// it fits the current template.
struct GetCaptionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_captions",
        title: "Get captions",
        description: """
        Reads an app's screenshot captions per locale and slot (from 1): headline, subhead, state (written, \
        edited, reviewed, machine-translated, proposed, or missing) and the headline's fit on iPhone with the \
        current template: fits, size in u, lines, fill and a label such as "1 line too many at 80 u". \
        A missing caption shows the primary locale's.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locales": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Locale codes such as de-DE or ja. Leave it out for every locale in scope.",
                ],
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let template = try draft.template()
        let locales = try arguments.optionalStrings("locales").map { try $0.map(draft.locale) } ?? draft.scopeLocales
        let entries = locales.map { locale -> JSONValue in
            let slots = (0..<draft.document.slotCount).map { slot -> JSONValue in
                let caption = draft.document.captions.caption(locale: locale.code, slot: slot)
                var entry: [String: JSONValue] = ["slot": .int(slot + 1), "name": .string(draft.document.slotName(slot))]
                guard let caption, !caption.headline.isEmpty else {
                    entry["state"] = "missing"
                    return .object(entry)
                }
                entry["headline"] = .string(caption.headline)
                if let subhead = caption.visibleSubhead { entry["subhead"] = .string(subhead) }
                entry["state"] = .string(caption.provenance.mcpState)
                let layout = draft.layout(template, locale: locale, slot: slot, displayType: .iPhone, caption: caption)
                entry["fit"] = layout.headline.mcpJSON
                if !layout.headlineFont.hasAllGlyphs { entry["glyphsMissing"] = .string(layout.headlineFont.missingCharacters) }
                return .object(entry)
            }
            return ["locale": .string(locale.code), "name": .string(locale.name), "slots": .array(slots)]
        }
        return .read(["appId": .string(draft.app.id), "templateVersion": .int(template.version), "locales": .array(entries)], target: draft.target)
    }
}
