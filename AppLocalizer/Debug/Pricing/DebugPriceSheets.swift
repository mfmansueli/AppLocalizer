//
//  DebugPriceSheets.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Price sheets for DEBUG scenes, from `PricingSampleData`. Lumen's
/// products use the sample subscriptions (custom prices in Mexico, Türkiye
/// and India, sales for the annual plan); other apps get equalized prices
/// for their base price. Every point has a made-up App Store Connect ID, so
/// queued changes carry complete requests.
@MainActor
enum DebugPriceSheets {
    private static var samples: [Commission: PricingSampleData] = [:]
    private static var sheets: [String: ProductPriceSheet] = [:]

    static func sample(for commission: Commission) -> PricingSampleData {
        if let sample = samples[commission] { return sample }
        let sample = commission == .smallBusiness ? PricingSampleData.shared : PricingSampleData(commission: commission)
        samples[commission] = sample
        return sample
    }

    static func sheet(for product: PricingProduct, commission: Commission, canReadSales: Bool) -> ProductPriceSheet {
        let key = "\(product.id).\(commission.rawValue).\(canReadSales)"
        if let sheet = sheets[key] { return sheet }
        let sheet = makeSheet(for: product, sample: sample(for: commission), canReadSales: canReadSales)
        sheets[key] = sheet
        return sheet
    }

    private static func makeSheet(for product: PricingProduct, sample: PricingSampleData, canReadSales: Bool) -> ProductPriceSheet {
        let subscription = PricingSampleSubscription.allCases.first { $0.productID == product.productID }
        let basePrice = subscription?.basePrice ?? product.basePrice ?? 0
        var prices: [String: TerritoryPrice] = [:]
        var ladders: [String: PricePointLadder] = [:]
        for territory in sample.catalog.territories {
            let ladder = identified(sample.ladder(for: territory), productID: product.id)
            let multiplier = sample.equalizationMultiplier(for: territory)
            let equalized = subscription.map { sample.equalizedPrice(for: territory, subscription: $0) }
                ?? ladder.nearest(to: basePrice * multiplier, rounding: .auto)?.customerPrice ?? basePrice * multiplier
            let current = subscription.map { sample.currentPrice(for: territory, subscription: $0) } ?? equalized
            prices[territory.id] = TerritoryPrice(
                territoryID: territory.id,
                current: point(current, in: ladder, territory: territory, sample: sample),
                equalized: point(equalized, in: ladder, territory: territory, sample: sample),
                equalizationMultiplier: multiplier
            )
            ladders[territory.id] = ladder
        }
        return ProductPriceSheet(
            productID: product.id,
            baseTerritoryID: "USA",
            basePrice: basePrice,
            prices: prices,
            ladders: ladders,
            exactLadderIDs: Set(ladders.keys),
            sales: sales(for: subscription, sample: sample, canReadSales: canReadSales)
        )
    }

    private static func identified(_ ladder: PricePointLadder, productID: String) -> PricePointLadder {
        PricePointLadder(territoryID: ladder.territoryID, currencyCode: ladder.currencyCode, points: ladder.points.map { point in
            var point = point
            point.appStoreConnectID = "debug-\(productID)-\(ladder.territoryID)-\(NSDecimalNumber(decimal: point.customerPrice).stringValue)"
            return point
        })
    }

    private static func point(_ price: Decimal, in ladder: PricePointLadder, territory: Territory, sample: PricingSampleData) -> PricePoint {
        ladder.point(at: price) ?? sample.calculator.offLadderPoint(price, territory: territory)
    }

    private static func sales(for subscription: PricingSampleSubscription?, sample: PricingSampleData, canReadSales: Bool) -> PricingSalesData {
        guard canReadSales else { return PricingSalesData(availability: .roleCannotRead) }
        guard subscription == .annual else { return PricingSalesData(availability: .available) }
        var signals: [String: SalesSignal] = [:]
        var priorChanges: [String: PriorPriceChange] = [:]
        for territory in sample.catalog.territories {
            signals[territory.id] = PricingSampleData.sales[territory.alpha2]
            priorChanges[territory.id] = sample.priorChange(for: territory)
        }
        return PricingSalesData(availability: .available, signals: signals, priorChanges: priorChanges)
    }
}
#endif
