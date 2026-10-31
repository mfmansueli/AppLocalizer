//
//  BeginSuggestionsTool.swift
//  AppLocalizer
//

import Foundation

/// `begin_suggestions`: Suggest Everything's plan. The assistant lists every
/// field it will suggest; AppLocalizer leaves out the ones it shouldn't
/// (locked, changed by the person, still coming from an Ask for one page,
/// or with the assistant's own suggestion still open) and starts a run,
/// which gives Overview its total and the pages their "coming" fields.
struct BeginSuggestionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "begin_suggestions",
        title: "Begin suggesting everything",
        description: """
        Starts a Suggest Everything run in AppLocalizer: after reading get_store_page and get_app_information, \
        list every field you'll suggest for the app. Plan entries are {area, locale | page, device, field}, \
        named as in suggest_fields. Returns run, the id to pass to every suggest_fields call; accepted, the \
        total AppLocalizer shows; and skipped, the entries it left out with a code: changed_by_you (the person \
        changed it and hasn't pushed), locked, in_another_request (an Ask for one page is still suggesting it), \
        already_suggested (your suggestion still waits for the person), unknown_field, unknown_locale, \
        not_permitted or invalid_value. Don't send the skipped ones. Suggestions sent with the run outside the \
        plan are added to the total. Call end_suggestions when you're done; the run also ends at the plan's \
        last item.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "version": MCPToolDefinition.string("The version string, e.g. 1.4, to check it's the one being prepared."),
                "plan": ["type": "array", "description": "One entry per field you'll suggest.", "items": Self.entrySchema],
            ],
            required: ["appId", "plan"]
        )
    )

    private static let entrySchema = MCPToolDefinition.schema(
        [
            "area": MCPToolDefinition.string("store or info."),
            "locale": MCPToolDefinition.string("For store: an App Store Connect locale code, e.g. en-US."),
            "page": MCPToolDefinition.string("For info: general, ageRating, accessibility or review."),
            "device": MCPToolDefinition.string("For accessibility: iphone, ipad, watch, vision, mac or tv."),
            "field": MCPToolDefinition.string("The field, question or feature, e.g. whatsNew, notes, wellness or voiceOver."),
        ],
        required: ["field"]
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        guard let store = context.workspace.suggestions else {
            throw MCPToolError.unavailable(String(localized: "Suggestions aren’t available right now. Ask the person to open AppLocalizer."))
        }
        let items = try arguments.array("plan").map { entry in
            guard let object = entry.objectValue else {
                throw MCPToolError.invalidArgument(name: "plan", expected: String(localized: "a list of {area, locale | page, device, field} objects"))
            }
            return try MCPSuggestionItem(object, isPlanned: true)
        }
        let app = try await context.workspace.app(matching: arguments.string("appId"))
        let session = try await MCPSuggestionSession(app: app, items: items, store: store, context: context, applies: false)
        try session.check(version: arguments.optionalString("version"))

        let source = SuggestionSource.assistant(client: context.clientName)
        var plan: [SuggestionTarget] = []
        var skipped: [JSONValue] = []
        for item in items {
            switch session.planned(item).flatMap({ Self.leftToOthers($0, store: store, appID: app.id, source: source) }) {
            case let .success(target): plan.append(target)
            case let .failure(skip): skipped.append(Self.json(item, skip))
            }
        }
        let run = store.startRun(appID: app.id, client: context.clientName, plan: plan)
        let result: JSONValue = [
            "run": .string(run.id),
            "accepted": .int(run.plan.count),
            "skipped": .array(skipped),
        ]
        return .read(result, target: String(localized: "\(app.name) · \(run.plan.count) planned"))
    }

    /// Fields the run leaves to others: an Ask for one page that's still
    /// going, or the assistant's own suggestion that's still open.
    private static func leftToOthers(
        _ target: SuggestionTarget,
        store: FieldSuggestionStore,
        appID: StoreApp.ID,
        source: SuggestionSource
    ) -> Result<SuggestionTarget, MCPPlanSkip> {
        if let request = store.request, request.appID == appID, request.covers(target) { return .failure(.inAnotherRequest) }
        if store.open(for: appID).contains(where: { $0.target == target && $0.source == source }) { return .failure(.alreadySuggested) }
        return .success(target)
    }

    /// `{field, locale | page, device, code, reason}`.
    private static func json(_ item: MCPSuggestionItem, _ skip: MCPPlanSkip) -> JSONValue {
        var entry: [String: JSONValue] = ["field": .string(item.field), "code": .string(skip.code), "reason": .string(skip.reason)]
        if let locale = item.locale { entry["locale"] = .string(locale) }
        if let page = item.page { entry["page"] = .string(page) }
        if let device = item.device { entry["device"] = .string(device) }
        return .object(entry)
    }
}
