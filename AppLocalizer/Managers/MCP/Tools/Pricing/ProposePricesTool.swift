//
//  ProposePricesTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_prices`: queues an assistant's prices for one subscription,
/// checked like the person's edits, for review in AppLocalizer.
struct ProposePricesTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_prices",
        title: "Propose prices",
        description: """
        Proposes new prices for one subscription: send territory and price, or several with prices: [{territory, \
        price}]. Prices are in the territory's currency and must be one of Apple's price points \
        (get_price_points); a price between points is refused with the two nearest ones. Each proposal is queued \
        for the person to review in AppLocalizer (status "queued"); nothing reaches App Store Connect until they \
        push. Today's price is "unchanged" and withdraws your earlier proposal for that territory. A \
        subscription without a price in the United States yet takes only its US price, queued as its starting \
        price: Apple equalizes it in every other country or region. Unknown territories or products, in-app \
        purchases and every price for an app set to Keep my prices are refused (status "refused") with the reason.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "productId": MCPToolDefinition.string("The subscription's Apple ID, product ID or name, from get_prices."),
                "territory": MCPToolDefinition.string("A territory code such as BRA or BR."),
                "price": ["type": "number", "description": "The new customer price in the territory's currency, e.g. 109.9."],
                "prices": [
                    "type": "array",
                    "description": "Several prices at once, instead of territory and price.",
                    "items": MCPToolDefinition.schema(
                        [
                            "territory": MCPToolDefinition.string("A territory code."),
                            "price": ["type": "number", "description": "The new customer price."],
                        ],
                        required: ["territory", "price"]
                    ),
                ],
            ],
            required: ["appId", "productId"]
        ),
        proposalKind: .prices
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let appID = try arguments.string("appId")
        let productID = try arguments.string("productId")
        let (proposals, isBatch) = try MCPPriceProposal.list(from: arguments)
        let catalog = try await MCPPriceCatalog.load(app: appID, in: context.workspace)

        var results: [JSONValue] = []
        var logLines: [MCPToolOutcome.LogLine] = []
        var outcomes: [MCPPriceProposer.Outcome] = []
        if let refusal = Self.refusal(for: productID, in: catalog) {
            for proposal in proposals {
                let outcome = MCPPriceProposer.Outcome.refused(reason: refusal, nearest: [])
                outcomes.append(outcome)
                results.append(Self.result(proposal, territoryID: nil, outcome: outcome))
                logLines.append(Self.logLine(outcome, target: "\(catalog.app.name) · \(productID) · \(proposal.territory)"))
            }
        } else {
            let product = try catalog.requireProduct(productID)
            guard var sheet = try await catalog.sheetIfPriced(for: product) else {
                let starting = try await MCPStartingPriceProposer.load(catalog: catalog, product: product, source: context.source)
                for proposal in proposals {
                    let outcome = starting.propose(proposal.price, territory: proposal.territory)
                    let territoryID = MCPStartingPriceProposer.isUnitedStates(proposal.territory) ? MCPStartingPriceProposer.territoryID : nil
                    outcomes.append(outcome)
                    results.append(Self.result(proposal, territoryID: territoryID, outcome: outcome))
                    logLines.append(Self.logLine(outcome, target: starting.target))
                }
                return Self.outcome(results: results, outcomes: outcomes, logLines: logLines, isBatch: isBatch)
            }
            let territories = proposals.map { sheet.territory(matching: $0.territory) }
            try await sheet.loadExactLadders(for: territories.compactMap { $0?.id })
            let proposer = MCPPriceProposer(sheet: sheet, source: context.source)
            for (proposal, territory) in zip(proposals, territories) {
                let outcome = territory.map { proposer.propose(proposal.price, in: $0) }
                    ?? .refused(reason: MCPPriceProposal.unknownTerritoryMessage(proposal.territory, product: product), nearest: [])
                outcomes.append(outcome)
                results.append(Self.result(proposal, territoryID: territory?.id, outcome: outcome))
                logLines.append(Self.logLine(outcome, target: sheet.target(territory?.name ?? proposal.territory)))
            }
        }
        return Self.outcome(results: results, outcomes: outcomes, logLines: logLines, isBatch: isBatch)
    }

    /// One proposal's result, or a batch's results with counts.
    private static func outcome(
        results: [JSONValue],
        outcomes: [MCPPriceProposer.Outcome],
        logLines: [MCPToolOutcome.LogLine],
        isBatch: Bool
    ) -> MCPToolOutcome {
        guard isBatch else { return MCPToolOutcome(result: results[0], isError: false, logLines: logLines) }
        let summary: JSONValue = [
            "results": .array(results),
            "queued": .int(outcomes.count { if case .queued = $0 { true } else { false } }),
            "unchanged": .int(outcomes.count { if case .unchanged = $0 { true } else { false } }),
            "refused": .int(outcomes.count { if case .refused = $0 { true } else { false } }),
        ]
        return MCPToolOutcome(result: summary, isError: false, logLines: logLines)
    }

    /// A reason every proposal in the call is refused: Keep my prices, an
    /// unknown product or an in-app purchase.
    private static func refusal(for productID: String, in catalog: MCPPriceCatalog) -> String? {
        if catalog.mode == .keepPrices { return catalog.keepPricesRefusal }
        guard let product = catalog.product(matching: productID) else { return catalog.unknownProductMessage(productID) }
        guard product.isInAppPurchase else { return nil }
        return String(localized: "\(product.name) is an in-app purchase. AppLocalizer only proposes subscription prices; pick a subscription from get_prices.")
    }

    private static func result(_ proposal: MCPPriceProposal, territoryID: String?, outcome: MCPPriceProposer.Outcome) -> JSONValue {
        var result: [String: JSONValue] = [
            "territory": .string(territoryID ?? proposal.territory),
            "price": MCPPriceValue.json(proposal.price),
        ]
        switch outcome {
        case let .queued(changeID, competing):
            result["status"] = "queued"
            result["changeId"] = .string(changeID)
            if competing {
                result["note"] = "The person set another price here too. Both wait in Review & Push, where they pick one."
            }
        case let .unchanged(note, _):
            result["status"] = "unchanged"
            result["note"] = .string(note)
        case let .refused(reason, nearest):
            result["status"] = "refused"
            result["reason"] = .string(reason)
            if !nearest.isEmpty { result["nearest"] = .array(nearest.map(MCPPriceValue.json)) }
        }
        return .object(result)
    }

    private static func logLine(_ outcome: MCPPriceProposer.Outcome, target: String) -> MCPToolOutcome.LogLine {
        switch outcome {
        case .queued: MCPToolOutcome.LogLine(target: target, outcome: .proposed)
        case .unchanged: MCPToolOutcome.LogLine(target: target, outcome: .read)
        case let .refused(reason, _): MCPToolOutcome.LogLine(target: target, outcome: .refused, reason: reason)
        }
    }
}
