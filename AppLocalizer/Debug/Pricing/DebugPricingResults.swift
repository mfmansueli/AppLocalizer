//
//  DebugPricingResults.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The prototype's Results: Lumen Plus Annual's recommended prices pushed on
/// Oct 26, 2026, and each territory's sales in the 28 days either side,
/// plus the offers and subscribers Lumen Plus Annual has. Only DEBUG scenes
/// and tests read it.
@MainActor
enum DebugPricingResults {
    /// The push Results compare: what Apply Recommended Prices… queues for
    /// Lumen Plus Annual (every territory but the base one whose strategy
    /// price differs from today's), pushed at 17:05 GMT on the sample day.
    static func annualPush(commission: Commission = .smallBusiness) -> PushRecord? {
        guard let product = annualProduct else { return nil }
        let factory = PriceChangeFactory(appID: DebugFixtures.AppID.lumen, product: product)
        let date = PricingSampleData.pushDate.addingTimeInterval(17 * 3600 + 5 * 60)
        let changes = followedRows(commission: commission).map { row in
            factory.change(for: row.territory, from: row.current, to: row.target, source: .suggestion, at: date)
        }
        return PushRecord(
            date: date,
            appID: DebugFixtures.AppID.lumen,
            appName: PricingSampleData.appName,
            title: String(localized: "Subscription Pricing · \(changes.count) territories"),
            pushed: changes
        )
    }

    /// Each pushed territory's 28 days before and after.
    static func salesComparison(commission: Commission = .smallBusiness) -> [String: SalesComparison] {
        let prices = Dictionary(uniqueKeysWithValues: followedRows(commission: commission).map { ($0.id, $0.target.customerPrice) })
        let results = DebugPriceSheets.sample(for: commission).results(pushing: prices)
        return Dictionary(uniqueKeysWithValues: results.map { ($0.territory.id, SalesComparison(before: $0.before, after: $0.after)) })
    }

    private static var annualProduct: PricingProduct? {
        DebugPricingCatalog.catalog(for: DebugFixtures.AppID.lumen).product(id: DebugPricingCatalog.lumenAnnualID)
    }

    /// The rows following the recommended strategy changes.
    private static func followedRows(commission: Commission) -> [PricingRow] {
        guard let product = annualProduct else { return [] }
        let sample = DebugPriceSheets.sample(for: commission)
        let rows = PricingRowBuilder(
            catalog: sample.catalog,
            calculator: sample.calculator,
            sheet: DebugPriceSheets.sheet(for: product, commission: commission, canReadSales: true),
            strategy: .recommended,
            showsSuggestions: true
        )
        .rows()
        return rows.filter { !$0.isBase && PricingRow.differs($0.target.customerPrice, $0.current.customerPrice) }
    }

    /// Existing subscribers per territory (alpha-3), where there are any.
    static func subscribers() -> [String: Int] {
        let sample = PricingSampleData.shared
        var counts: [String: Int] = [:]
        for territory in sample.catalog.territories {
            let count = sample.subscribers(in: territory)
            if count > 0 { counts[territory.id] = count }
        }
        return counts
    }
}
#endif
