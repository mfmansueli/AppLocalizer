//
//  GetListingTool.swift
//  AppLocalizer
//

import Foundation

/// `get_listing`: an app's store texts per locale as the Store Page shows
/// them, each field's limit, and the glossary to respect.
struct GetListingTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_listing",
        title: "Get store listing",
        description: """
        Reads an app's store listing in AppLocalizer: the newest editable version (else the live one, which is \
        read-only), its primary locale, and each locale's texts with anything waiting in review laid on top. \
        `states` says which fields are missing, over the limit, machine-translated or already proposed. \
        `fields` gives each field's level and limit: name, subtitle and privacyPolicyUrl belong to the app; \
        promotionalText, description, keywords (comma-separated, counted in bytes), whatsNew, supportUrl and \
        marketingUrl belong to the version. `glossary.keepUntranslated` lists terms to leave as they are, and \
        `glossary.tone` the tone to write in. Pass `locales` to read only some.
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
        let draft = try await MCPListingDraft.load(app: arguments.string("appId"), in: context.workspace)
        let listing = draft.listing
        let locales = try draft.locales(arguments.optionalStrings("locales"))
        let glossary = context.workspace.glossary()
        let fields = listing.fields.map { field -> (String, JSONValue) in
            let info: JSONValue = [
                "level": .string(field.level == .app ? "app" : "version"),
                "limit": field.limitJSON,
                "editable": .bool(listing.canEdit(field)),
            ]
            return (field.rawValue, info)
        }
        let result: JSONValue = [
            "appId": .string(draft.app.id),
            "app": .string(draft.app.name),
            "version": draft.versionJSON,
            "primaryLocale": .string(listing.primaryLocale.code),
            "fields": .object(Dictionary(uniqueKeysWithValues: fields)),
            "glossary": [
                "keepUntranslated": .array(glossary.terms.map(JSONValue.string)),
                "tone": .string(glossary.tone.rawValue),
            ],
            "locales": .array(locales.map { Self.entry(for: $0, in: listing) }),
        ]
        return .read(result, target: draft.target)
    }

    private static func entry(for locale: StoreLocale, in listing: StoreListing) -> JSONValue {
        var texts: [String: JSONValue] = [:]
        var states: [String: JSONValue] = [:]
        for field in listing.fields {
            let value = listing.value(field, in: locale)
            if !value.isEmpty { texts[field.rawValue] = .string(value) }
            if let note = listing.coverageState(of: field, in: locale).assistantNote { states[field.rawValue] = .string(note) }
        }
        var entry: [String: JSONValue] = ["code": .string(locale.code), "name": .string(locale.name), "texts": .object(texts)]
        if !states.isEmpty { entry["states"] = .object(states) }
        return .object(entry)
    }
}
