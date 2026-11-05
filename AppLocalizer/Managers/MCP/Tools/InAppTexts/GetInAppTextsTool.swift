//
//  GetInAppTextsTool.swift
//  AppLocalizer
//

import Foundation

/// `get_in_app_texts`: what `propose_in_app_texts` works on, as Store Page
/// → In-App Texts shows it.
struct GetInAppTextsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_in_app_texts",
        title: "Get In-App Texts",
        description: """
        Reads an app's In-App Texts in AppLocalizer: the subscription group's display name and each \
        subscription's and in-app purchase's display name and description, per locale, shown on the purchase \
        sheet and in Settings → Subscriptions. `columns` lists each text's id (group.name, <productId>.name, \
        <productId>.description) and its limit. Per locale, `texts` has the current text (App Store Connect's \
        with anything queued on top), `live` App Store Connect's where a queued change differs, and `missing` \
        the columns still empty. App Store Connect needs at least one group name localization before a \
        subscription can be added for review, and a name to create a locale. Pass `locales` to read only some. \
        Propose texts with propose_in_app_texts.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locales": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "App Store Connect locale codes such as de-DE or ja. Leave it out for every locale.",
                ],
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPInAppTextsDraft.load(app: arguments.string("appId"), in: context.workspace)
        return try .read(draft.json(locales: arguments.optionalStrings("locales")), target: draft.target)
    }
}
