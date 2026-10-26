//
//  MCPPriceCatalog.swift
//  AppLocalizer
//

import Foundation

/// One app's subscriptions and in-app purchases and its pricing mode, as
/// the price tools read them, and each product's prices on demand.
@MainActor
struct MCPPriceCatalog {
    /// Proceeds and price points use the Small Business Program rate: the
    /// tools don't read the person's commission setting.
    static let commission = Commission.smallBusiness

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
        let services = workspace.services.pricing
        do {
            let sheet = try await services.priceSheet(for: product, commission: Self.commission)
            let calculator = PriceCalculator(catalog: .standard, snapshot: services.indexSnapshot(), commission: Self.commission)
            return MCPPriceSheet(app: app, product: product, mode: mode, sheet: sheet, calculator: calculator, workspace: workspace)
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read the prices of \(product.name): \(error.localizedDescription)"))
        }
    }

    /// "Keep my prices" as the refusal names it.
    var keepPricesRefusal: String {
        String(localized: """
        \(app.name) is set to “\(PricingMode.keepPrices.title)”, so AppLocalizer never proposes prices for it. The \
        person can change the pricing mode in its Subscription Pricing section.
        """)
    }
}
