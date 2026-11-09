//
//  ProposeRetentionMessageTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_retention_message`: an assistant's retention message, or its
/// words in some languages, its image or the subscriptions that show it,
/// checked like an edit in Pricing → Retention and queued in Review & Push.
/// With `suggestion`, a shorter wording for one language that the person
/// takes with Use Shorter Version instead.
struct ProposeRetentionMessageTool: MCPTool {
    var store = RetentionDraftStore.shared
    /// Where images sent with the proposal wait for the push.
    var imageDirectory = RetentionImageFiles.directory

    /// The arguments, typed apart so the definition type-checks quickly.
    private static let properties: [String: JSONValue] = [
        "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
        "messageId": MCPToolDefinition.string("An existing message's id or reference name, from get_retention. Leave it out to make a new message."),
        "referenceName": MCPToolDefinition.string("A new message's internal name in App Store Connect (≤64). It can't change once pushed."),
        "subscriptions": [
            "type": "array",
            "items": ["type": "string"],
            "description": "The subscriptions that show it (ids, product IDs or names). An existing message only adds them.",
        ],
        "kind": ["type": "string", "enum": ["message", "image", "offer"], "description": "What the message shows besides its words."],
        "locale": MCPToolDefinition.string("The locale of header and body, e.g. en-US."),
        "header": MCPToolDefinition.string("The header, at most 66 characters."),
        "body": MCPToolDefinition.string("The message, at most 144 characters."),
        "texts": [
            "type": "array",
            "items": [
                "type": "object",
                "properties": [
                    "locale": ["type": "string"],
                    "header": ["type": "string"],
                    "body": ["type": "string"],
                ],
                "required": ["locale"],
            ],
            "description": "Several languages at once, each with locale, header and body.",
        ],
        "imagePath": MCPToolDefinition.string("A PNG AppLocalizer can read (it's sandboxed; prefer imageBase64)."),
        "imageBase64": MCPToolDefinition.string("The PNG itself in base64: 3840 wide, 160 to 2160 tall, no transparency."),
        "imageName": MCPToolDefinition.string("The image's name in the Asset Library."),
        "suggestion": [
            "type": "boolean",
            "description": "For one language that runs too long: offer the wording as a shorter version the person takes, instead of queuing it.",
        ],
        "evidence": [
            "type": "array",
            "items": ["type": "string"],
            "description": "Where the wording comes from, e.g. Lumen/Paywall/PaywallView.swift:40 — lists photos, prompts and search",
        ],
    ]

    let definition = MCPToolDefinition(
        name: "propose_retention_message",
        title: "Propose Retention Message",
        description: """
        Proposes a retention message for an app: the header (≤66 characters) and body (≤144) subscribers see on \
        Apple's Confirm Cancellation screen, by locale. Leave messageId out for a new message, with referenceName \
        and subscriptions (an app has at most 10 messages; a subscription shows one, so naming one that shows \
        another message moves it). kind is message, image (add imageBase64 or imagePath: a PNG 3840 wide, 160 to \
        2160 tall, no transparency, readable in light and dark) or offer (the subscription's retention offers show \
        with it; propose them with propose_retention_offer). Write the source language first (get_retention's \
        sourceLocale); AppLocalizer translates the rest, or pass more languages in texts. Anything too long or that \
        App Store Connect would refuse is refused with the reasons (status "refused"). An accepted proposal waits in \
        Review & Push (status "queued"), and proposing the same message again updates it. With suggestion true and \
        one locale, the wording is offered under that language's too-long warning instead (status "suggested"). \
        Nothing reaches App Store Connect until the person pushes.
        """,
        inputSchema: MCPToolDefinition.schema(Self.properties, required: ["appId"]),
        proposalKind: .storeText
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let retention = try await RetentionMCPContext.load(app: arguments.string("appId"), in: context.workspace, store: store)
        let proposal = try RetentionMessageProposal.make(from: arguments, in: retention, client: context.clientName, imageDirectory: imageDirectory)
        let target = "\(retention.target) · \(RetentionText.trimmed(proposal.message.referenceName))"
        if try arguments.optionalBool("suggestion") == true {
            return try suggest(proposal, in: retention, client: context.clientName, target: target)
        }
        let messageCount = retention.messages.count + (retention.messages.contains { $0.id == proposal.message.id } ? 0 : 1)
        let builder = retention.builder(with: proposal.message)
        var reasons = proposal.refusals
        if reasons.isEmpty { reasons = builder.problems(for: proposal.message, messageCount: messageCount).map(\.message) }
        if reasons.isEmpty, !proposal.message.hasChanges, !builder.changesOffers(proposal.message), !retention.isQueued(proposal.message) {
            reasons.append(String(localized: "That’s what App Store Connect has already."))
        }
        guard reasons.isEmpty else { return Self.refused(reasons, messageID: proposal.message.id, target: target) }

        let changeID = RetentionChangeBuilder.messageChangeID(appID: retention.app.id, messageID: proposal.message.id)
        let source = retention.queue.change(id: changeID)?.source ?? context.source
        let evidence = try arguments.optionalStrings("evidence") ?? []
        retention.queue.upsert(builder.change(for: proposal.message, source: source, messageCount: messageCount, evidence: evidence))
        retention.store.keep(proposal.message, appID: retention.app.id, queued: true)
        return MCPToolOutcome(
            result: Self.queuedResult(proposal, changeID: changeID, builder: builder),
            isError: false,
            logLines: [.init(target: target, outcome: .proposed)]
        )
    }

    /// One language's shorter wording, kept for Use Shorter Version.
    private func suggest(_ proposal: RetentionMessageProposal, in retention: RetentionMCPContext, client: String, target: String) throws -> MCPToolOutcome {
        // A draft that hasn't been pushed counts: that's where long words are found.
        let isKnown = retention.messages.contains { $0.id == proposal.message.id }
        guard isKnown, proposal.locales.count == 1, let locale = proposal.locales.first else {
            throw MCPToolError.invalidArgument(name: "suggestion", expected: String(localized: "one locale of an existing message (messageId)"))
        }
        guard proposal.refusals.isEmpty else { return Self.refused(proposal.refusals, messageID: proposal.message.id, target: target) }
        let text = proposal.message.text(for: locale)
        let current = retention.messages.first { $0.id == proposal.message.id }?.text(for: locale)
        let suggestion = RetentionSuggestion(
            messageID: proposal.message.id,
            locale: locale,
            header: text.header == current?.header ? nil : text.header,
            body: text.body,
            client: client
        )
        retention.store.suggest(suggestion, appID: retention.app.id)
        let result: JSONValue = [
            "status": "suggested",
            "messageId": .string(proposal.message.id),
            "locale": .string(locale),
            "note": "The person sees it under the language's too-long warning and takes it with Use Shorter Version.",
        ]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: "\(target) · \(locale)", outcome: .proposed)])
    }

    private static func refused(_ reasons: [String], messageID: String, target: String) -> MCPToolOutcome {
        let result: JSONValue = ["status": "refused", "messageId": .string(messageID), "reasons": .array(reasons.map { .string($0) })]
        return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: target, outcome: .refused, reason: reasons.joined(separator: " "))])
    }

    private static func queuedResult(_ proposal: RetentionMessageProposal, changeID: String, builder: RetentionChangeBuilder) -> JSONValue {
        let message = proposal.message
        let missing = builder.languages(of: message).filter { !message.text(for: $0.code).isComplete }.map(\.code)
        var result: [String: JSONValue] = [
            "status": "queued",
            "changeId": .string(changeID),
            "messageId": .string(message.id),
            "languages": .array(proposal.locales.map { .string($0) }),
            "note": """
            When the person pushes, App Store Connect gets the message's words, image and subscriptions, and it goes \
            to App Review; subscribers see it once Apple approves it. Test it by canceling a sandbox subscription.
            """,
        ]
        if !missing.isEmpty {
            result["missingLanguages"] = .array(missing.map { .string($0) })
            result["next"] = "Translate All in Pricing → Retention fills in the missing languages, or propose them in texts."
        }
        if !proposal.replaces.isEmpty { result["replacesMessageOn"] = .array(proposal.replaces.map { .string($0) }) }
        return .object(result)
    }
}
