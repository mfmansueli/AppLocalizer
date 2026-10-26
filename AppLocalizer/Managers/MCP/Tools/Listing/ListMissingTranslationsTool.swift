//
//  ListMissingTranslationsTool.swift
//  AppLocalizer
//

import Foundation

/// `list_missing_translations`: every editable field that's empty in a
/// locale while the primary locale has text, with that text and the limit.
struct ListMissingTranslationsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "list_missing_translations",
        title: "List missing translations",
        description: """
        Lists the store-listing fields that are empty in a locale while the primary locale has text, for the \
        newest editable version of an app: per locale, each field with its source text in the primary locale and \
        its limit. Fields already proposed or waiting in review don't count as missing. URLs (copyAsIs) are \
        copied, not translated. Translate each field and send it with propose_listing_text.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locales": [
                    "type": "array",
                    "items": ["type": "string"],
                    "description": "Only these App Store Connect locale codes. Leave it out for every locale.",
                ],
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPListingDraft.load(app: arguments.string("appId"), in: context.workspace)
        let listing = draft.listing
        let primary = listing.primaryLocale
        var entries: [JSONValue] = []
        var count = 0
        for locale in try draft.locales(arguments.optionalStrings("locales")) where locale != primary {
            let missing = listing.fields.compactMap { field -> JSONValue? in
                let source = listing.value(field, in: primary)
                guard listing.canEdit(field), listing.value(field, in: locale).isEmpty, !source.isEmpty else { return nil }
                return ["field": .string(field.rawValue), "source": .string(source), "limit": field.limitJSON, "copyAsIs": .bool(field.isURL)]
            }
            guard !missing.isEmpty else { continue }
            count += missing.count
            entries.append(["locale": .string(locale.code), "name": .string(locale.name), "fields": .array(missing)])
        }
        var result: [String: JSONValue] = [
            "appId": .string(draft.app.id),
            "app": .string(draft.app.name),
            "version": draft.versionJSON,
            "primaryLocale": .string(primary.code),
            "missingCount": .int(count),
            "locales": .array(entries),
        ]
        if !listing.version.isEditable {
            result["note"] = .string("""
            Version \(listing.version.versionString) is read-only, so only name, subtitle and privacyPolicyUrl can be \
            proposed until the person creates a new version.
            """)
        }
        return .read(.object(result), target: draft.target)
    }
}
