//
//  SuggestFieldsTool.swift
//  AppLocalizer
//

import Foundation

/// `suggest_fields`: an assistant's suggested values for Store Page and App
/// Information fields. Each item is checked like an edit (the field, the
/// limit, a locked version, the person's permissions) and shows under its
/// field for the person to accept, edit or dismiss. Nothing changes until
/// they do, unless they chose "Suggest and edit drafts" and the call says
/// `apply`: then the value is queued as an unpushed change marked with the
/// assistant.
struct SuggestFieldsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "suggest_fields",
        title: "Suggest field values",
        description: """
        Suggests values for an app's fields in AppLocalizer; each one shows under its field until the person \
        accepts, edits or dismisses it. Items are {area, locale | page, device, field, value, reason, evidence}: \
        area store with a locale code and a Store Page field (\(ListingField.mcpNames.joined(separator: ", "))), \
        or area info with page general (copyright, primaryCategory, secondaryCategory, release), page review \
        (contactFirstName, contactLastName, contactPhone, contactEmail, notes), page ageRating (field is a \
        question, value one of its answers) or page accessibility with a device (iphone, ipad, watch, vision, \
        mac, tv; field is a feature, value yes or no). Give a one-sentence reason and \
        evidence such as {kind: "git", ref: "v1.3..4f2c91a"} or {kind: "code", ref: "File.swift:18"}. Per item, \
        status is queued, unchanged (the field already has that value or you suggested it already), replaced \
        (your older open suggestion for the field was replaced) or refused with a code: over_limit (with count), \
        unknown_field, unknown_locale, locked (the version is in review), not_permitted, invalid_value or \
        invalid_answer (not one of the question's or feature's answers). Pass \
        total, how many you'll send in all, so AppLocalizer shows progress. apply: true queues the values as \
        changes instead, only when the person allowed editing drafts. Read get_store_page and \
        get_app_information first.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "version": MCPToolDefinition.string("The version string, e.g. 1.4, to check it's the one being prepared."),
                "items": ["type": "array", "description": "The suggestions, one per field.", "items": Self.itemSchema],
                "total": ["type": "integer", "description": "How many suggestions you'll send in all, across calls."],
                "apply": ["type": "boolean", "description": "Queue the values as changes. Only with “Suggest and edit drafts”."],
            ],
            required: ["appId", "items"]
        )
    )

    private static let itemSchema = MCPToolDefinition.schema(
        [
            "area": MCPToolDefinition.string("store or info."),
            "locale": MCPToolDefinition.string("For store: an App Store Connect locale code, e.g. en-US."),
            "page": MCPToolDefinition.string("For info: general, ageRating, accessibility or review."),
            "device": MCPToolDefinition.string("For accessibility: iphone, ipad, watch, vision, mac or tv."),
            "field": MCPToolDefinition.string("The field, question or feature, e.g. whatsNew, notes, wellness or voiceOver."),
            "value": MCPToolDefinition.string(
                "The suggested value, within the field's limit. Categories and release by id; an answer by name, e.g. Yes or Infrequent."
            ),
            "reason": MCPToolDefinition.string("One sentence: why this value."),
            "evidence": ["type": "array", "items": evidenceSchema],
        ],
        required: ["field", "value"]
    )

    private static let evidenceSchema = MCPToolDefinition.schema(
        ["kind": MCPToolDefinition.string("git, code, review, …"), "ref": MCPToolDefinition.string("What to look at.")],
        required: ["kind", "ref"]
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        guard let store = context.workspace.suggestions else {
            throw MCPToolError.unavailable(String(localized: "Suggestions aren’t available right now. Ask the person to open AppLocalizer."))
        }
        let items = try arguments.array("items").map { item in
            guard let object = item.objectValue else {
                throw MCPToolError.invalidArgument(name: "items", expected: String(localized: "a list of {area, locale | page, field, value, reason} objects"))
            }
            return try MCPSuggestionItem(object)
        }
        let wantsApply = try arguments.optionalBool("apply") ?? false
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        var session = try await MCPSuggestionSession(app: app, items: items, store: store, context: context, applies: wantsApply && context.editsDrafts)
        try session.check(version: arguments.optionalString("version"))
        if let total = try arguments.optionalInt("total") {
            store.noteExpectedTotal(total, client: context.clientName, appID: app.id)
        }

        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        for item in items {
            var settled = session.suggest(item)
            if wantsApply, !session.applies, settled.result["status"] != "refused" {
                settled.result["note"] = "apply needs “Suggest and edit drafts” in AppLocalizer; it's waiting as a suggestion instead."
            }
            results.append(.object(settled.result))
            logLines.append(settled.logLine)
        }
        session.commit()
        let summary: JSONValue = [
            "results": .array(results),
            "queued": .int(results.count { ["queued", "replaced", "applied"].contains($0["status"]?.stringValue) }),
            "refused": .int(results.count { $0["status"]?.stringValue == "refused" }),
        ]
        return MCPToolOutcome(result: summary, isError: false, logLines: logLines)
    }

    // MARK: - Helpers

    /// A `version` argument that isn't the one being prepared.
    static func check(version: String?, against shown: String, app: String) throws {
        guard let version, version != shown else { return }
        throw MCPToolError.notFound(String(localized: "\(app)’s version being prepared is \(shown), not \(version). Suggestions are for \(shown)."))
    }

    /// `general`, `ageRating`, `accessibility` or `review`, as MCP names
    /// App Information's pages.
    nonisolated static func mcpPageName(_ page: String) -> String {
        page == AppInformationPage.appReview.rawValue ? "review" : page
    }

    /// The page an assistant named: `general`, `ageRating` (or `age`),
    /// `accessibility`, `review` or `appReview`.
    nonisolated static func page(named name: String) -> AppInformationPage? {
        switch name.replacingOccurrences(of: "_", with: "").lowercased() {
        case "general": .general
        case "agerating", "age": .ageRating
        case "accessibility": .accessibility
        case "review", "appreview": .appReview
        default: nil
        }
    }
}
