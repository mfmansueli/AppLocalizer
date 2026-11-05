//
//  DebugPricingServices.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// `PricingServices` for DEBUG scenes: the sample apps' canned data, or
/// `error`. Never contacts App Store Connect.
@MainActor
struct DebugPricingServices: PricingServices {
    var error: AppStoreConnectError?
    /// Thrown by price sheets alone, e.g. `PricingSheetError.noStartingPrice`.
    var sheetError: PricingSheetError?
    /// How long a price sheet takes to arrive; long enough keeps the skeleton up.
    var sheetDelay: Duration?
    /// Answers the first sheet at once and delays only the ones after it (a refresh).
    var delaysRefreshOnly = false
    /// False plays a key whose role can't read Sales and Trends.
    var canReadSales = true
    /// The state a scene opens in once prices have loaded.
    var launch: PricingDebugLaunch?
    let calls = DebugPricingCallLog()

    func summary(for app: StoreApp) async throws -> PricingSummary {
        if let error { throw error }
        return DebugSummaries.pricing(for: app.id)
    }

    func catalog(for app: StoreApp) async throws -> PricingCatalog {
        if let error { throw error }
        return DebugPricingCatalog.catalog(for: app.id)
    }

    func priceSheet(for product: PricingProduct, commission: Commission) async throws -> ProductPriceSheet {
        let request = calls.recordSheetRequest()
        if let sheetDelay, !delaysRefreshOnly || request > 1 { try await Task.sleep(for: sheetDelay) }
        if let error { throw error }
        if let sheetError { throw sheetError }
        return DebugPriceSheets.sheet(for: product, commission: commission, canReadSales: canReadSales)
    }

    func ladders(for product: PricingProduct, territoryIDs: [String], commission: Commission) async throws -> [String: PricePointLadder] {
        let ladders = DebugPriceSheets.sheet(for: product, commission: commission, canReadSales: canReadSales).ladders
        return ladders.filter { territoryIDs.contains($0.key) }
    }

    /// Lumen Plus Annual's offers; other products have none.
    func offers(for product: PricingProduct) async throws -> [SubscriptionOffer] {
        if let error { throw error }
        return isLumenAnnual(product) ? PricingSampleData.offers : []
    }

    /// Lumen Plus Annual's existing subscribers; other products have none.
    func subscribers(for product: PricingProduct) async throws -> [String: Int]? {
        if let error { throw error }
        return isLumenAnnual(product) ? DebugPricingResults.subscribers() : [:]
    }

    /// Lumen Plus Annual's sales around the sample push; nil for a key that
    /// can't read sales.
    func salesComparison(for product: PricingProduct, territoryIDs: [String], changedOn _: Date) async throws -> [String: SalesComparison]? {
        if let error { throw error }
        guard canReadSales else { return nil }
        guard isLumenAnnual(product) else { return [:] }
        return DebugPricingResults.salesComparison().filter { territoryIDs.contains($0.key) }
    }

    /// The sample snapshot, which already holds the imported custom index.
    func indexSnapshot() -> PriceIndexSnapshot {
        PricingSampleData.shared.snapshot
    }

    private func isLumenAnnual(_ product: PricingProduct) -> Bool {
        product.id == DebugPricingCatalog.lumenAnnualID
    }
}
#endif
