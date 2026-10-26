//
//  GetPricePointsTool.swift
//  AppLocalizer
//

import Foundation

/// `get_price_points`: Apple's price points around a price in one
/// territory, since only those can be proposed.
struct GetPricePointsTool: MCPTool {
    /// Points listed on each side of the price.
    static let pointsPerSide = 6

    let definition = MCPToolDefinition(
        name: "get_price_points",
        title: "Get price points",
        description: """
        Lists Apple's price points for one product in one territory around today's price, or around `near`: \
        each point's customer price and proceeds (Small Business Program rate, after tax) in the territory's \
        currency. Only these prices can be proposed with propose_prices.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "productId": MCPToolDefinition.string("The product's Apple ID, product ID or name, from get_prices."),
                "territory": MCPToolDefinition.string("A territory code such as BRA or BR, or its name."),
                "near": ["type": "number", "description": "A price in the territory's currency to list points around. Defaults to today's price."],
            ],
            required: ["appId", "productId", "territory"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let catalog = try await MCPPriceCatalog.load(app: arguments.string("appId"), in: context.workspace)
        let product = try catalog.requireProduct(arguments.string("productId"))
        let code = try arguments.string("territory")
        let near = try arguments.values["near"].flatMap { value -> Decimal? in
            guard !value.isNull else { return nil }
            guard let price = MCPPriceValue.decimal(from: value) else {
                throw MCPToolError.invalidArgument(name: "near", expected: String(localized: "a positive price, e.g. 109.9"))
            }
            return price
        }
        var sheet = try await catalog.sheet(for: product)
        guard let territory = sheet.territory(matching: code) else {
            throw MCPToolError.notFound(MCPPriceProposal.unknownTerritoryMessage(code, product: product))
        }
        try await sheet.loadExactLadders(for: [territory.id])
        let current = sheet.sheet.prices[territory.id]?.current.customerPrice ?? 0
        let ladder = sheet.ladder(for: territory)
        let points = Self.points(in: ladder, around: near ?? current)
        var result: [String: JSONValue] = [
            "territory": .string(territory.id),
            "name": .string(territory.name),
            "currency": .string(territory.currencyCode),
            "current": MCPPriceValue.json(current),
            "points": .array(points.map { point in
                var entry: [String: JSONValue] = [
                    "price": MCPPriceValue.json(point.customerPrice),
                    "proceeds": MCPPriceValue.json(point.proceeds.rounded(scale: 2)),
                ]
                if !PricingRow.differs(point.customerPrice, current) { entry["current"] = true }
                return .object(entry)
            }),
        ]
        if let near { result["near"] = MCPPriceValue.json(near) }
        return .read(.object(result), target: sheet.target(territory.name))
    }

    /// Up to `pointsPerSide` points below the price and as many from it up.
    static func points(in ladder: PricePointLadder, around price: Decimal) -> [PricePoint] {
        let index = ladder.points.firstIndex { $0.customerPrice >= price } ?? ladder.points.count
        let lower = max(0, index - pointsPerSide)
        let upper = min(ladder.points.count, index + pointsPerSide)
        return Array(ladder.points[lower..<upper])
    }
}
