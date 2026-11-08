//
//  ProposeRetentionOfferTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_retention_offer`: an assistant's retention offer (offer type 5)
/// for one subscription, checked like New Offer… in Pricing → Retention and
/// queued in Review & Push, which creates it with Apple's equalized prices
/// and shows it with the subscription's retention message.
struct ProposeRetentionOfferTool: MCPTool {
    var store = RetentionDraftStore.shared

    private static let properties: [String: JSONValue] = [
        "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
        "subscription": MCPToolDefinition.string("The subscription's id, product ID or name, from get_retention."),
        "referenceName": MCPToolDefinition.string("The offer's internal name (≤64); left out, it's named after its terms."),
        "mode": [
            "type": "string",
            "enum": .array(RetentionOfferMode.allCases.map { .string($0.rawValue) }),
            "description": "FREE_TRIAL (free for a while), PAY_AS_YOU_GO (a lower price each period) or PAY_UP_FRONT (one lower price).",
        ],
        "months": ["type": "integer", "description": "How long the offer lasts in months: 1, 2, 3 or 6, or 12 for a yearly subscription."],
        "price": [
            "type": ["number", "string"],
            "description": "The offer's price in the United States in US dollars (each period for PAY_AS_YOU_GO); not for FREE_TRIAL.",
        ],
        "paidMonths": ["type": "integer", "description": "Months someone must have paid before they're eligible: 1 to 24, 36, 48 or 60."],
        "waitMonths": ["type": "integer", "description": "Optional months between two retention offers for one person: 2 to 24."],
        "evidence": [
            "type": "array",
            "items": ["type": "string"],
            "description": "Why this offer, e.g. Lumen/Store/Plans.swift:22 — monthly is 4.99",
        ],
    ]

    let definition = MCPToolDefinition(
        name: "propose_retention_offer",
        title: "Propose Retention Offer",
        description: """
        Proposes a retention offer for one subscription: what Apple can show with the retention message when \
        someone taps Cancel Subscription (offer type 5). mode is FREE_TRIAL, PAY_AS_YOU_GO or PAY_UP_FRONT; months \
        is how long it lasts; price is in US dollars in the United States, and every other territory gets Apple's \
        equalized price. A subscription has at most 10 retention offers; Apple picks who's eligible and the best \
        offer. Anything App Store Connect would refuse is refused with the reasons (status "refused"). An accepted \
        proposal waits in Review & Push (status "queued"); the subscription's message must be kind "offer" to show \
        it (propose_retention_message). Nothing reaches App Store Connect until the person pushes.
        """,
        inputSchema: MCPToolDefinition.schema(Self.properties, required: ["appId", "subscription", "mode", "months"]),
        proposalKind: .prices
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let retention = try await RetentionMCPContext.load(app: arguments.string("appId"), in: context.workspace, store: store)
        let subscription = try retention.requireSubscription(arguments.string("subscription"))
        let draft = try Self.draft(from: arguments, subscription: subscription)
        let offerID = draft.offerID(for: subscription)
        let changeID = RetentionChangeBuilder.offerChangeID(appID: retention.app.id, subscriptionID: subscription.id, offerID: offerID)
        let target = "\(retention.target) · \(draft.referenceName(for: subscription))"

        var reasons: [String] = []
        let previous = retention.queue.change(id: changeID)
        if let previous, previous.source != context.source {
            reasons.append(String(localized: "\(previous.source.title) already has this offer in Review & Push."))
        }
        // Proposing the same offer again replaces it.
        let existing = retention.offers.filter { $0.subscriptionID == subscription.id && !($0.isQueued && $0.offerID == offerID) }
        reasons += draft.problems(for: subscription, existing: existing).map(\.message)
        guard reasons.isEmpty, let offer = draft.offer(for: subscription, existing: existing) else {
            let result: JSONValue = ["status": "refused", "reasons": .array(reasons.map { .string($0) })]
            return MCPToolOutcome(result: result, isError: false, logLines: [.init(target: target, outcome: .refused, reason: reasons.joined(separator: " "))])
        }
        let evidence = try arguments.optionalStrings("evidence") ?? []
        retention.queue.upsert(retention.builder().offerChange(for: offer, source: context.source, evidence: evidence))
        let shows = retention.messages.first { $0.subscriptionIDs.contains(subscription.id) }
        var result: [String: JSONValue] = [
            "status": "queued",
            "changeId": .string(changeID),
            "offerId": .string(offer.offerID),
            "terms": .string(offer.terms(basePrice: subscription.basePrice, period: subscription.period)),
        ]
        if let shows, shows.kind != .offer {
            result["next"] = .string(String(localized: """
            \(subscription.name) shows “\(shows.referenceName)” as \(shows.kind.rawValue); propose it with kind "offer" \
            (messageId \(shows.id)) so the offer shows with it.
            """))
        } else if shows == nil {
            result["next"] = "No message shows on this subscription yet: propose one with kind \"offer\"."
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    private static func draft(from arguments: MCPToolArguments, subscription: RetentionSubscription) throws -> RetentionOfferDraft {
        let modeText = try arguments.string("mode").uppercased()
        guard let mode = RetentionOfferMode(rawValue: modeText == "FREE" ? RetentionOfferMode.free.rawValue : modeText) else {
            throw MCPToolError.invalidArgument(name: "mode", expected: "FREE_TRIAL, PAY_AS_YOU_GO or PAY_UP_FRONT")
        }
        guard let months = try arguments.optionalInt("months"), months > 0 else {
            throw MCPToolError.invalidArgument(name: "months", expected: String(localized: "a whole number of months, e.g. 3"))
        }
        var draft = RetentionOfferDraft(subscriptionID: subscription.id, mode: mode, months: months)
        draft.name = try arguments.optionalString("referenceName").map(RetentionText.trimmed) ?? ""
        if mode.hasPrice {
            guard let value = arguments.values["price"], let price = MCPPriceValue.decimal(from: value) else {
                throw MCPToolError.invalidArgument(name: "price", expected: String(localized: "a price in US dollars, e.g. 2.49"))
            }
            draft.priceText = NSDecimalNumber(decimal: price).stringValue
        }
        draft.paidMonths = try arguments.optionalInt("paidMonths") ?? 1
        draft.waitMonths = try arguments.optionalInt("waitMonths")
        return draft
    }
}
