//
//  MCPStartingPriceProposer.swift
//  AppLocalizer
//

import Foundation

/// `propose_prices` for a subscription without a price in the United
/// States yet (made in App Store Connect, or a new one whose push stopped
/// before its prices): its US price becomes Set Starting Price, the same
/// change Pricing's Set Starting Price queues
/// (`NewSubscriptionChangeBuilder.startingPriceChange`). The push sets it in
/// the United States and Apple's equalized price everywhere else. Other
/// territories wait until it's pushed; a price between Apple's US points is
/// refused with the nearest ones.
@MainActor
struct MCPStartingPriceProposer {
    let app: StoreApp
    let product: PricingProduct
    /// Apple's price points in the United States for this subscription.
    let ladder: PricePointLadder
    let queue: ChangeQueue
    let source: ChangeSource

    static let territoryID = NewSubscription.baseTerritoryID

    static var territory: Territory? {
        TerritoryCatalog.standard.territory(alpha3: territoryID)
    }

    /// Reads Apple's US price points for the subscription.
    static func load(catalog: MCPPriceCatalog, product: PricingProduct, source: ChangeSource) async throws -> MCPStartingPriceProposer {
        try await MCPStartingPriceProposer(
            app: catalog.app,
            product: product,
            ladder: ladder(catalog: catalog, product: product),
            queue: catalog.workspace.changes,
            source: source
        )
    }

    /// Apple's US price points for a subscription without prices.
    static func ladder(catalog: MCPPriceCatalog, product: PricingProduct) async throws -> PricePointLadder {
        let ladders: [String: PricePointLadder]
        do {
            ladders = try await catalog.workspace.services.pricing.ladders(
                for: product,
                territoryIDs: [territoryID],
                commission: catalog.workspace.commission()
            )
        } catch {
            throw MCPToolError.unavailable(String(localized: "Couldn’t read Apple’s price points for \(product.name): \(error.localizedDescription)"))
        }
        guard let ladder = ladders[territoryID], !ladder.points.isEmpty else {
            throw MCPToolError.unavailable(String(localized: "App Store Connect sent no US price points for \(product.name)."))
        }
        return ladder
    }

    var changeID: PendingChange.ID {
        NewSubscriptionChangeBuilder.startingPriceChangeID(appID: app.id, productID: product.productID)
    }

    /// "Bruma · Bruma Premium Monthly · United States".
    var target: String {
        "\(app.name) · \(product.name) · \(Self.territory?.name ?? Self.territoryID)"
    }

    /// Queues the US price as the starting price, or says why it can't.
    /// The territory is the one the assistant wrote.
    func propose(_ price: Decimal, territory identifier: String) -> MCPPriceProposer.Outcome {
        guard Self.isUnitedStates(identifier), let territory = Self.territory else {
            return .refused(reason: String(localized: """
            \(product.name) has no price in the United States yet, so only its US price can be proposed: Apple \
            equalizes it in every other country or region (Set Starting Price). Propose territory USA; other \
            prices can change once it’s pushed.
            """), nearest: [])
        }
        guard let point = ladder.point(at: price) else {
            return MCPPriceProposer.notAPricePoint(price, in: territory, ladder: ladder)
        }
        if let existing = queue.change(id: changeID), Self.price(of: existing) == point.customerPrice {
            return .unchanged(note: String(localized: "That starting price already waits in Review & Push; nothing new was queued."), withdrew: false)
        }
        let change = NewSubscriptionChangeBuilder(app: app).startingPriceChange(for: product, price: point.customerPrice, source: source)
        queue.upsert(change)
        let stored = queue.change(id: change.id)
        let competing = stored?.source != source && stored?.alternative?.source == source
        return .queued(changeID: change.id, competing: competing)
    }

    /// USA, US or "United States", case ignored.
    static func isUnitedStates(_ identifier: String) -> Bool {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let territory = TerritoryCatalog.standard.territory(code: trimmed.uppercased())
            ?? TerritoryCatalog.standard.territories.first {
                $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
        return territory?.id == Self.territoryID
    }

    /// The US price a queued starting price sets.
    private static func price(of change: PendingChange) -> Decimal? {
        change.requests.lazy.compactMap(SubscriptionStartingPrices.init).first?.customerPrice
    }
}
