//
//  GetScreenshotContextTool.swift
//  AppLocalizer
//

import Foundation

/// `get_screenshot_context`: what an assistant needs before captioning:
/// display types and sizes, slot names, the locales in scope, the primary
/// captions, the listing's name and subtitle, and the template version.
struct GetScreenshotContextTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_screenshot_context",
        title: "Get screenshot context",
        description: """
        Reads what an app's localized App Store screenshots are made of in AppLocalizer: the display types \
        templates render (iphone 6.9″, ipad 13″) and their pixel sizes, the slots (numbered from 1) and their \
        names, the locales in scope (each gets its own screenshots), the primary locale's captions, the \
        listing's name and subtitle, and the template version. Captions are short marketing headlines drawn \
        above or below a real screenshot of the app; they must fit the template, so check them with \
        measure_caption before proposing.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "version": MCPToolDefinition.string("The version string, e.g. 1.4. Leave it out for the version being prepared."),
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let appID = try arguments.string("appId")
        let draft = try await MCPScreenshotsDraft.load(app: appID, in: context.workspace)
        let document = draft.document
        let listing = try? await MCPListingDraft.load(app: appID, in: context.workspace)
        let slots = (0..<document.slotCount).map { slot -> JSONValue in
            var entry: [String: JSONValue] = ["slot": .int(slot + 1), "name": .string(document.slotName(slot))]
            if let caption = document.captions.caption(locale: draft.primary.code, slot: slot) {
                entry["primaryHeadline"] = .string(caption.headline)
                if let subhead = caption.visibleSubhead { entry["primarySubhead"] = .string(subhead) }
            }
            return .object(entry)
        }
        var result: [String: JSONValue] = [
            "appId": .string(draft.app.id),
            "app": .string(draft.app.name),
            "primaryLocale": .string(draft.primary.code),
            "displayTypes": .array(ScreenshotDisplayType.rendered.map(\.mcpJSON)),
            "slots": .array(slots),
            "localesInScope": .array(draft.scopeLocales.map { ["code": .string($0.code), "name": .string($0.name)] }),
            "templateVersion": document.history.map { .int($0.currentNumber) } ?? .null,
            "hasCaptures": .bool(!document.captures.isEmpty),
        ]
        if let listing {
            result["version"] = listing.versionJSON
            result["listing"] = [
                "name": .string(listing.listing.value(.name, in: draft.primary)),
                "subtitle": .string(listing.listing.value(.subtitle, in: draft.primary)),
            ]
        }
        return .read(.object(result), target: draft.target)
    }
}
