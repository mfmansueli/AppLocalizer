//
//  MCPPriceCatalog.swift
//  AppLocalizer
//

import Foundation

/// One app's subscriptions and in-app purchases and its pricing mode, as
/// the price tools read them, and each product's prices on demand.
@MainActor
struct MCPPriceCatalog {
    let app: StoreApp
    let catalog: PricingCatalog
    let mode: PricingMode
    let workspace: MCPWorkspace

    static func load(app identifier: String, in workspace: MCPWorkspace) async throws -> MCPPriceCatalog {
        let app = try await workspace.app(matching: identifier)
        let catalog: PricingCatalog
        do {
            catalog = try await workspace.services.pricing.catalog(for: app)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read \(app.name)’s subscriptions: \(error.localizedDescription)"))
        }
        return MCPPriceCatalog(app: app, catalog: catalog, mode: workspace.pricingModes.mode(for: app.id), workspace: workspace)
    }

    /// The product an assistant means: its Apple ID, product ID or name
    /// (case ignored).
    func product(matching identifier: String) -> PricingProduct? {
        let wanted = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return catalog.products.first { product in
            [product.id, product.productID, product.name].contains { $0.lowercased() == wanted }
        }
    }

    /// Why no product matched, naming the app's products.
    func unknownProductMessage(_ identifier: String) -> String {
        guard !catalog.isEmpty else {
            return String(localized: "\(app.name) has no subscriptions or in-app purchases to price.")
        }
        let names = catalog.products.map { "\($0.name) (\($0.id))" }.formatted(.list(type: .or))
        return String(localized: "\(app.name) has no product “\(identifier)”. Use get_prices; its products are \(names).")
    }

    /// The product, or a not-found error naming the app's products.
    func requireProduct(_ identifier: String) throws -> PricingProduct {
        guard let product = product(matching: identifier) else { throw MCPToolError.notFound(unknownProductMessage(identifier)) }
        return product
    }

    /// The product's prices in every territory, with the queue's proposals.
    func sheet(for product: PricingProduct) async throws -> MCPPriceSheet {
        guard let sheet = try await sheetIfPriced(for: product) else {
            throw MCPToolError.unavailable(noStartingPriceMessage(product))
        }
        return sheet
    }

    /// The product's prices, or nil for a subscription without a price in
    /// the United States yet, whose US price sets its starting price
    /// (`MCPStartingPriceProposer`).
    func sheetIfPriced(for product: PricingProduct) async throws -> MCPPriceSheet? {
        let services = workspace.services.pricing
        // Proceeds use the commission set in Settings → General.
        let commission = workspace.commission()
        do {
            let sheet = try await services.priceSheet(for: product, commission: commission)
            let calculator = PriceCalculator(catalog: .standard, snapshot: services.indexSnapshot(), commission: commission)
            return MCPPriceSheet(app: app, product: product, mode: mode, sheet: sheet, calculator: calculator, workspace: workspace)
        } catch PricingSheetError.noStartingPrice {
            return nil
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read the prices of \(product.name): \(error.localizedDescription)"))
        }
    }

    /// Why a subscription without a US price has no prices to read, and
    /// how to give it some.
    func noStartingPriceMessage(_ product: PricingProduct) -> String {
        String(localized: """
        \(product.name) has no price in the United States yet. Propose its US price with propose_prices (territory \
        USA, a point from get_price_points): Apple equalizes it in every other country or region.
        """)
    }

    /// "Keep my prices" as the refusal names it.
    var keepPricesRefusal: String {
        String(localized: """
        \(app.name) is set to “\(PricingMode.keepPrices.title)”, so AppLocalizer never proposes prices for it. The \
        person can change the pricing mode in its Subscription Pricing section.
        """)
    }
}
