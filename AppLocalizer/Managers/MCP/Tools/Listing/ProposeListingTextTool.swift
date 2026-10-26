//
//  ProposeListingTextTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_listing_text`: an assistant's text for store-listing fields,
/// validated like an edit in the Store Page and queued for review, one field
/// or a batch at a time. Over-limit text and read-only fields are refused
/// with the reason; a field the person changed too keeps both versions.
struct ProposeListingTextTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_listing_text",
        title: "Propose store text",
        description: """
        Proposes text for store-listing fields of an app's newest editable version (name, subtitle and \
        privacyPolicyUrl also when only the live version exists). Send one field with locale, field and text, or \
        several with proposals: [{locale, field, text}]. Each proposal is checked like a manual edit: over the \
        limit, not an https URL, a locale the app doesn't have or a read-only field is refused with the reason \
        (status "refused"); fix it and propose again. Accepted proposals are queued for the person to review in \
        AppLocalizer (status "queued"); nothing reaches App Store Connect until they push. Fields: \
        \(ListingField.mcpNames.joined(separator: ", ")).
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "locale": MCPToolDefinition.string("An App Store Connect locale code, e.g. de-DE."),
                "field": MCPToolDefinition.string("The field, e.g. subtitle or whatsNew."),
                "text": MCPToolDefinition.string("The proposed text, within the field's limit."),
                "proposals": [
                    "type": "array",
                    "description": "Several proposals at once, instead of locale, field and text.",
                    "items": MCPToolDefinition.schema(
                        [
                            "locale": MCPToolDefinition.string("An App Store Connect locale code."),
                            "field": MCPToolDefinition.string("The field."),
                            "text": MCPToolDefinition.string("The proposed text."),
                        ],
                        required: ["locale", "field", "text"]
                    ),
                ],
            ],
            required: ["appId"]
        ),
        proposalKind: .storeText
    )

    /// One field's proposed text.
    private struct Proposal {
        var locale: String
        var field: ListingField
        var text: String

        init(_ arguments: MCPToolArguments) throws {
            locale = try arguments.string("locale")
            let name = try arguments.string("field")
            guard let field = ListingField.matching(name) else {
                throw MCPToolError.invalidArgument(name: "field", expected: String(localized: "one of \(ListingField.mcpNames.joined(separator: ", "))"))
            }
            self.field = field
            text = try arguments.string("text")
        }
    }

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let batch = try arguments.optionalArray("proposals")
        let proposals = try batch.map { items in
            try items.map { item in
                guard let object = item.objectValue else {
                    throw MCPToolError.invalidArgument(name: "proposals", expected: String(localized: "a list of {locale, field, text} objects"))
                }
                return try Proposal(MCPToolArguments(object))
            }
        } ?? [Proposal(arguments)]

        var draft = try await MCPListingDraft.load(app: arguments.string("appId"), in: context.workspace)
        let outcomes = proposals.map { draft.propose($0.text, for: $0.field, locale: $0.locale, by: context.clientName) }
        let changeIDs = draft.commit(to: context.workspace.changes)

        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        var settled: [ListingProposalOutcome] = []
        for (proposal, proposed) in zip(proposals, outcomes) {
            let changeID = StoreLocaleCatalog.locale(code: proposal.locale).flatMap { changeIDs[ListingFieldKey($0, proposal.field)] }
            // Proposed back to App Store Connect's text: nothing stays queued.
            let outcome = proposed.isQueued && changeID == nil ? .unchanged : proposed
            settled.append(outcome)
            results.append(Self.result(proposal, outcome: outcome, changeID: changeID))
            logLines.append(Self.logLine(proposal, outcome: outcome, target: draft.target(locale: proposal.locale, field: proposal.field)))
        }
        guard batch != nil else { return MCPToolOutcome(result: results[0], isError: false, logLines: logLines) }
        let summary: JSONValue = [
            "results": .array(results),
            "queued": .int(settled.count(where: \.isQueued)),
            "refused": .int(settled.count(where: \.isRefused)),
        ]
        return MCPToolOutcome(result: summary, isError: false, logLines: logLines)
    }

    private static func result(_ proposal: Proposal, outcome: ListingProposalOutcome, changeID: PendingChange.ID?) -> JSONValue {
        var result: [String: JSONValue] = ["locale": .string(proposal.locale), "field": .string(proposal.field.rawValue)]
        switch outcome {
        case .queued:
            result["status"] = "queued"
            result["changeId"] = changeID.map(JSONValue.string) ?? .null
        case .conflict:
            result["status"] = "queued"
            result["changeId"] = changeID.map(JSONValue.string) ?? .null
            result["note"] = "The person changed this field too. Both versions wait in Review & Push, where they pick one."
        case .unchanged:
            result["status"] = "unchanged"
            result["note"] = "That's already the field's text in App Store Connect or in review; nothing new was queued."
        case let .refused(refusal):
            result["status"] = "refused"
            result["reason"] = .string(reason(for: refusal))
            if case let .overLimit(count, _) = refusal {
                result["count"] = .int(count)
                result["limit"] = proposal.field.limitJSON
            }
        }
        return .object(result)
    }

    private static func logLine(_: Proposal, outcome: ListingProposalOutcome, target: String) -> MCPToolOutcome.LogLine {
        switch outcome {
        case .queued, .conflict: MCPToolOutcome.LogLine(target: target, outcome: .proposed)
        case .unchanged: MCPToolOutcome.LogLine(target: target, outcome: .read)
        case let .refused(refusal): MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason(for: refusal))
        }
    }

    /// The refusal as the assistant and the activity log read it, with what
    /// to do next.
    private static func reason(for refusal: ListingProposalRefusal) -> String {
        switch refusal {
        case .overLimit, .invalidURL: String(localized: "\(refusal.reason) Fix it and propose again.")
        case .unknownLocale, .localeNotInListing, .notEditable: refusal.reason
        }
    }
}
