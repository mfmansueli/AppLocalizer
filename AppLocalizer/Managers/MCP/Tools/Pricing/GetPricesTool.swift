//
//  GetPricesTool.swift
//  AppLocalizer
//

import Foundation

/// `get_prices`: an app's pricing mode, and for each product (or one) every
/// territory's price, proceeds, suggestion and queued price.
struct GetPricesTool: MCPTool {
    static let hint = """
    Each territory: `territory` (App Store Connect's three-letter code), `currency`, `price` (today's customer \
    price, tax included) and `proceeds` (what the developer receives at the Small Business Program's 15% \
    commission, after tax), both in that currency. `suggested` and `reason` appear only when the app shows \
    suggestions and the suggestion differs from today's price. `queued` is a price waiting in Review & Push and \
    `queuedBy` who proposed it; `alternative` is another assistant's or the person's competing version. Prices \
    must be one of Apple's price points: use get_price_points, then propose_prices.
    """

    let definition = MCPToolDefinition(
        name: "get_prices",
        title: "Get prices",
        description: """
        Reads an app's subscription and in-app purchase prices in every territory: today's price and proceeds, \
        AppLocalizer's suggestion with its reason (when the app shows suggestions) and any price waiting in \
        review, plus the app's pricing mode (keepPrices, showSuggestions or applyRecommended). Apps set to \
        keepPrices refuse every price proposal. Pass productId to read one product; `hint` explains the fields.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "productId": MCPToolDefinition.string("A product's Apple ID, product ID or name. Leave it out for every product."),
            ],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let catalog = try await MCPPriceCatalog.load(app: arguments.string("appId"), in: context.workspace)
        let products = try arguments.optionalString("productId").map { try [catalog.requireProduct($0)] } ?? catalog.catalog.products
        var entries: [JSONValue] = []
        for product in products {
            let sheet: MCPPriceSheet
            do {
                sheet = try await catalog.sheet(for: product)
            } catch {
                // One product without prices (a new subscription) doesn't hide the others.
                guard products.count > 1 else { throw error }
                entries.append([
                    "productId": .string(product.id),
                    "name": .string(product.name),
                    "sku": .string(product.productID),
                    "unavailable": .string(error.localizedDescription),
                ])
                continue
            }
            var entry = sheet.productJSON
            entry["territories"] = .array(sheet.rows().map { Self.entry(for: $0, in: sheet) })
            entries.append(.object(entry))
        }
        let result: JSONValue = [
            "appId": .string(catalog.app.id),
            "app": .string(catalog.app.name),
            "pricingMode": .string(catalog.mode.rawValue),
            "hint": .string(Self.hint),
            "products": .array(entries),
        ]
        let target = products.count == 1 ? "\(catalog.app.name) · \(products[0].name)" : String(localized: "\(catalog.app.name) · prices")
        return .read(result, target: target)
    }

    /// One territory, leaving out what doesn't apply.
    private static func entry(for row: PricingRow, in sheet: MCPPriceSheet) -> JSONValue {
        var entry: [String: JSONValue] = [
            "territory": .string(row.territory.id),
            "currency": .string(row.territory.currencyCode),
            "price": MCPPriceValue.json(row.current.customerPrice),
            "proceeds": MCPPriceValue.json(row.current.proceeds.rounded(scale: 2)),
        ]
        if let recommendation = row.recommendation, PricingRow.differs(recommendation.price.customerPrice, row.current.customerPrice) {
            entry["suggested"] = MCPPriceValue.json(recommendation.price.customerPrice)
            entry["reason"] = .string(recommendation.reason)
        }
        if let queued = row.queued {
            entry["queued"] = MCPPriceValue.json(queued.price)
            entry["queuedBy"] = .string(queued.source.title)
            let alternative = sheet.queuedChange(for: row.territory)?.alternative
            if let alternative, let price = CurrencyFormat.forCurrency(row.territory.currencyCode).parse(alternative.newValue) {
                entry["alternative"] = ["price": MCPPriceValue.json(price), "by": .string(alternative.source.title)]
            }
        }
        return .object(entry)
    }
}
