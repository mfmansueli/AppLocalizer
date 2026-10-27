//
//  PricingModelFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Lumen Journal's sample prices (`DebugPricingServices`) as the Pricing
/// screen's models hold them, so view-model tests start from the
/// prototype's numbers.
@MainActor
enum PricingModelFixtures {
    static let appID = DebugFixtures.AppID.lumen
    static let commission = Commission.smallBusiness

    static var app: StoreApp { DebugFixtures.lumen }

    static func annual(sourceLocation: SourceLocation = #_sourceLocation) throws -> PricingProduct {
        try #require(
            DebugPricingCatalog.catalog(for: appID).product(id: DebugPricingCatalog.lumenAnnualID),
            sourceLocation: sourceLocation
        )
    }

    /// World Bank prices allowed up to 130% of equalized: the `schedule`
    /// scene's strategy, under which seven territories go up.
    static var premiumStrategy: PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.method = .priceIndex
        strategy.indexSource = .worldBank
        strategy.discountOnly = false
        strategy.ceiling = Decimal(130) / 100
        return strategy
    }

    /// Lumen Plus Annual's matrix; `follows` fills every territory as Apply
    /// Recommended Prices… does.
    static func matrix(
        queue: ChangeQueue = ChangeQueue(),
        strategy: PricingStrategy = .recommended,
        mode: PricingMode = .showSuggestions,
        follows: Bool = false
    ) async throws -> PriceMatrixModel {
        let product = try annual()
        let matrix = PriceMatrixModel(
            appID: appID,
            product: product,
            sheet: DebugPriceSheets.sheet(for: product, commission: commission, canReadSales: true),
            services: DebugPricingServices(),
            queue: queue,
            strategy: strategy,
            calculator: PriceCalculator(snapshot: PricingSampleData.shared.snapshot, commission: commission),
            mode: mode
        )
        if follows { await matrix.follow() }
        return matrix
    }

    /// Lumen Journal's Pricing section, loaded on Lumen Plus Annual.
    static func viewModel(
        queue: ChangeQueue = ChangeQueue(),
        services: DebugPricingServices = DebugPricingServices(),
        mode: PricingMode = .showSuggestions
    ) async -> PricingViewModel {
        let modes = PricingModeStore(defaults: nil, modes: [appID: mode])
        let model = PricingViewModel(app: app, services: services, queue: queue, modes: modes, commission: commission)
        await model.load()
        return model
    }
}
#endif
