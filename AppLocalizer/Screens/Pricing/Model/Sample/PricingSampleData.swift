//
//  PricingSampleData.swift
//  AppLocalizer
//

import Foundation

/// The design prototype's sample world for "Lumen Journal", for DEBUG scenes,
/// previews and tests: simulated ladders and equalized prices, current
/// prices, sales, subscribers, earlier changes and results.
///
/// Everything here is illustrative. The real app reads price points,
/// equalizations and sales from App Store Connect.
struct PricingSampleData: Sendable {
    /// Built once: simulating 175 ladders takes a moment.
    static let shared = PricingSampleData()

    static let appName = "Lumen Journal"
    /// When the sample push happened, for Results.
    static let pushDate = date("2026-10-26")
    /// The custom index's import.
    static let customIndexFileName = "Regional reference prices.csv"
    static let customIndexImportDate = date("2026-10-20")

    let catalog: TerritoryCatalog
    /// The bundled snapshot plus the sample custom index.
    let snapshot: PriceIndexSnapshot
    let commission: Commission
    let calculator: PriceCalculator
    let recommender: PriceRecommender
    /// Simulated ladders by territory ID.
    let ladders: [String: PricePointLadder]

    init(catalog: TerritoryCatalog = .standard, snapshot: PriceIndexSnapshot? = nil, commission: Commission = .smallBusiness) {
        let base = snapshot ?? (try? PriceIndexSnapshot.bundled()) ?? .empty
        let snapshot = base.adding(Self.customIndex(catalog: catalog))
        self.catalog = catalog
        self.snapshot = snapshot
        self.commission = commission
        calculator = PriceCalculator(catalog: catalog, snapshot: snapshot, commission: commission)
        recommender = PriceRecommender(calculator: calculator)
        var ladders: [String: PricePointLadder] = [:]
        for territory in catalog.territories {
            ladders[territory.id] = SimulatedPriceLadder.make(
                territory: territory,
                equalizationMultiplier: Self.equalizationMultiplier(currency: territory.currencyCode),
                commission: commission
            )
        }
        self.ladders = ladders
    }

    /// The base territory, the United States.
    var baseTerritory: Territory? { catalog.territory(alpha3: "USA") }

    func territory(_ code: String) -> Territory? {
        catalog.territory(code: code)
    }

    func ladder(for territory: Territory) -> PricePointLadder {
        ladders[territory.id] ?? PricePointLadder(territoryID: territory.id, currencyCode: territory.currencyCode, points: [])
    }

    static func equalizationMultiplier(currency code: String) -> Decimal {
        Decimal(exactly: equalizationMultipliers[code] ?? 1)
    }

    func equalizationMultiplier(for territory: Territory) -> Decimal {
        Self.equalizationMultiplier(currency: territory.currencyCode)
    }

    /// Simulated equalization: base price × multiplier, snapped to the
    /// currency's usual ending (R$ 219,90 for $39.99).
    func equalizedPrice(for territory: Territory, subscription: PricingSampleSubscription) -> Decimal {
        let target = subscription.basePrice * equalizationMultiplier(for: territory)
        return ladder(for: territory).nearest(to: target, rounding: .auto)?.customerPrice ?? target
    }

    /// Today's price: equalized, except Mexico, Türkiye and India on Annual.
    func currentPrice(for territory: Territory, subscription: PricingSampleSubscription) -> Decimal {
        if subscription == .annual, let custom = Self.customAnnualPrices[territory.alpha2] { return custom }
        return equalizedPrice(for: territory, subscription: subscription)
    }

    /// The calculator's input with today's price.
    func input(for territory: Territory, subscription: PricingSampleSubscription) -> PriceCalculationInput {
        PriceCalculationInput(
            territory: territory,
            basePrice: subscription.basePrice,
            equalizedPrice: equalizedPrice(for: territory, subscription: subscription),
            ladder: ladder(for: territory),
            currentPrice: currentPrice(for: territory, subscription: subscription),
            equalizationMultiplier: equalizationMultiplier(for: territory)
        )
    }

    /// Sales exist for Annual only, as in the prototype. Pass
    /// `canReadSales: false` for an App Manager key without Sales and Trends.
    func evidence(for territory: Territory, subscription: PricingSampleSubscription, canReadSales: Bool = true) -> SalesEvidence {
        guard canReadSales else { return .unavailable }
        guard subscription == .annual else { return SalesEvidence(canReadSales: true) }
        return SalesEvidence(
            canReadSales: true,
            signal: Self.sales[territory.alpha2],
            baseSignal: Self.sales["US"],
            priorChange: priorChange(for: territory)
        )
    }

    /// The suggestion as the Suggestions columns show it.
    func recommendation(
        for territory: Territory,
        subscription: PricingSampleSubscription,
        canReadSales: Bool = true
    ) -> Recommendation {
        recommender.recommend(
            input(for: territory, subscription: subscription),
            evidence: evidence(for: territory, subscription: subscription, canReadSales: canReadSales)
        )
    }

    /// Earlier Annual changes: Mexico (lifted starts) and Türkiye (didn't).
    func priorChange(for territory: Territory) -> PriorPriceChange? {
        switch territory.alpha2 {
        case "MX":
            PriorPriceChange(
                date: Self.date("2026-07-14"),
                previousPrice: 739,
                before: SalesSignal(pageViews: 2050, starts: 16),
                after: SalesSignal(pageViews: 2100, starts: 22)
            )
        case "TR":
            PriorPriceChange(
                date: Self.date("2026-07-14"),
                previousPrice: Decimal(159_999) / 100,
                before: SalesSignal(pageViews: 1150, starts: 8),
                after: SalesSignal(pageViews: 1200, starts: 7)
            )
        default: nil
        }
    }

    /// Existing subscribers in a territory (0 when none).
    func subscribers(in territory: Territory) -> Int {
        Self.subscribers[territory.alpha2] ?? 0
    }

    /// The prototype's custom index as an imported `PriceIndex`.
    static func customIndex(catalog: TerritoryCatalog = .standard) -> PriceIndex {
        var levels: [String: Decimal] = [:]
        for (code, factor) in customFactors {
            if let territory = catalog.territory(alpha2: code) { levels[territory.id] = Decimal(exactly: factor) }
        }
        let edition = PriceIndexEdition(
            label: "Imported " + PricingText.date(customIndexImportDate),
            badge: "Custom",
            provenanceLabel: "custom index",
            date: customIndexImportDate,
            newerEdition: nil
        )
        return PriceIndex(source: .custom, edition: edition, levels: levels, fileName: customIndexFileName)
    }

    static func date(_ day: String) -> Date {
        (try? PriceIndexEdition.parseDay(day)) ?? .distantPast
    }
}
