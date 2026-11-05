//
//  PricingDebugScenes.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// The Subscription Pricing section's DEBUG scenes (`-AppLocalizerDebugScene <id>`),
/// as the design's Pricing and Customize boards show them. `DebugSceneView`
/// asks here for any id it doesn't know itself.
///
/// - `mode-sheet`: Lumen Journal's first visit, asking for a pricing mode.
/// - `pricing-keep`: Tempo Metronome with Keep my prices, Europe only.
/// - `pricing-suggest`, `pricing-breakdown`: Lumen Annual with why Brazil's
///   price is suggested, or Brazil's breakdown after three suggestions applied.
/// - `pricing-applied`: every territory filled, Germany set by hand.
/// - `pricing-bulk`: four Asia Pacific rows selected.
/// - `pricing-nosales`: a key whose role can't read sales.
/// - `pricing-skeleton`: the table skeleton during a refresh that never ends.
/// - `pricing-refresh`: a refresh (as after a push) whose prices arrive after
///   two seconds of skeleton.
/// - `pricing-nosubs`: Quiet Timer, which has nothing to price.
/// - `iap`: Lumen Lifetime, an in-app purchase.
/// - `custom`, `custom-tune`, `custom-compare`, `custom-csv`: the Customize…
///   inspector with a Big Mac strategy, its limits and exclusions, Brazil's
///   sources compared, and a CSV import waiting for confirmation.
/// - `pricing-map`, `pricing-hist`: every territory filled, as the tile map
///   with Brazil hovered, or as the histogram.
/// - `schedule`: the schedule sheet for a strategy that allows premiums, with
///   the increases' existing subscribers.
/// - `results`, `results-waiting`: Lumen Annual's Oct 26 push four weeks
///   later, or on its first day.
/// - `offers`: Lumen Annual's promotional offer.
enum PricingDebugScenes {
    typealias AppIDs = DebugFixtures.AppID

    static let ids = [
        "mode-sheet", "pricing-keep", "pricing-suggest", "pricing-breakdown", "pricing-applied", "pricing-bulk",
        "pricing-nosales", "pricing-skeleton", "pricing-refresh", "pricing-nosubs", "iap",
        "custom", "custom-tune", "custom-compare", "custom-csv",
        "pricing-map", "pricing-hist", "schedule", "results", "results-waiting", "offers",
    ]

    @MainActor
    static func view(for id: String) -> AnyView? {
        pricingScene(id) ?? stateScene(id) ?? customizeScene(id) ?? viewScene(id)
    }

    @MainActor
    private static func pricingScene(_ id: String) -> AnyView? {
        switch id {
        case "mode-sheet":
            scene(pricingModes: DebugWorkspace.pricingModes.filter { $0.key != AppIDs.lumen })
        case "pricing-keep":
            scene(app: AppIDs.tempo, launch: PricingDebugLaunch(region: .europe))
        case "pricing-suggest":
            scene(launch: PricingDebugLaunch(selection: ["BRA"], popover: .suggestion("BRA")))
        case "pricing-breakdown":
            scene(launch: PricingDebugLaunch(appliedSuggestions: ["BRA", "IND", "IDN"], selection: ["BRA"], popover: .breakdown("BRA")))
        case "pricing-applied":
            scene(launch: PricingDebugLaunch(follows: true, manualPrices: ["DEU": Decimal(string: "34.99") ?? 0]))
        case "pricing-bulk":
            scene(launch: PricingDebugLaunch(region: .asiaPacific, selection: ["IND", "IDN", "PHL", "VNM"]))
        default:
            nil
        }
    }

    @MainActor
    private static func stateScene(_ id: String) -> AnyView? {
        switch id {
        case "pricing-nosales":
            scene(services: DebugPricingServices(canReadSales: false))
        case "pricing-skeleton":
            scene(services: DebugPricingServices(sheetDelay: .seconds(3600), delaysRefreshOnly: true, launch: PricingDebugLaunch(refreshes: true)))
        case "pricing-refresh":
            scene(services: DebugPricingServices(sheetDelay: .seconds(2), delaysRefreshOnly: true, launch: PricingDebugLaunch(refreshes: true)))
        case "pricing-nosubs":
            scene(app: AppIDs.quiet, pricingModes: DebugWorkspace.pricingModes.merging([AppIDs.quiet: .showSuggestions]) { $1 })
        case "iap":
            scene(launch: PricingDebugLaunch(productID: DebugPricingCatalog.lumenLifetimeID))
        default:
            nil
        }
    }

    @MainActor
    private static func customizeScene(_ id: String) -> AnyView? {
        switch id {
        case "custom":
            scene(launch: PricingDebugLaunch(
                follows: true, strategy: customStrategy, selection: ["BRA"], popover: .breakdown("BRA"), inspectorTab: .strategy
            ))
        case "custom-tune":
            scene(launch: PricingDebugLaunch(
                follows: true, strategy: customStrategy, selection: ["JPN"], inspectorTab: .strategy,
                collapsedSections: [.method, .priceIndex, .fallback]
            ))
        case "custom-compare":
            scene(launch: PricingDebugLaunch(follows: true, strategy: customStrategy, selection: ["BRA"], inspectorTab: .territory))
        case "custom-csv":
            scene(launch: PricingDebugLaunch(strategy: customIndexStrategy, inspectorTab: .strategy, showsImport: true))
        default:
            nil
        }
    }

    @MainActor
    private static func viewScene(_ id: String) -> AnyView? {
        switch id {
        case "pricing-map":
            scene(launch: PricingDebugLaunch(follows: true, display: .map, hoveredTerritory: "BRA"))
        case "pricing-hist":
            scene(launch: PricingDebugLaunch(follows: true, display: .histogram))
        case "schedule":
            scene(launch: PricingDebugLaunch(
                follows: true, strategy: premiumStrategy, schedule: PriceSchedule(startDay: "2026-11-02"), showsSchedule: true,
                today: PricingSampleData.pushDate
            ))
        case "results":
            resultsScene(today: PricingSampleData.date("2026-11-23"))
        case "results-waiting":
            resultsScene(today: PricingSampleData.pushDate)
        case "offers":
            scene(launch: PricingDebugLaunch(tab: .offers, offerID: "promo"))
        default:
            nil
        }
    }

    /// Lumen Annual's push on Oct 26, 2026 on top of the usual history.
    @MainActor
    private static func resultsScene(today: Date) -> AnyView {
        let records = [DebugPricingResults.annualPush()].compactMap(\.self) + DebugWorkspace.pushRecords
        return scene(launch: PricingDebugLaunch(tab: .results, today: today), pushRecords: records)
    }

    /// World Bank prices that may go up to 130% of equalized, so some
    /// territories rise.
    private static var premiumStrategy: PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.method = .priceIndex
        strategy.indexSource = .worldBank
        strategy.discountOnly = false
        strategy.ceiling = Decimal(130) / 100
        return strategy
    }

    /// Big Mac Index with World Bank as fallback, intensity 80%, floor 35%
    /// and Japan excluded.
    private static var customStrategy: PricingStrategy {
        var strategy = PricingStrategy.recommended
        strategy.method = .priceIndex
        strategy.indexSource = .bigMac
        strategy.fallback = [.index(.worldBank), .regionMedian, .equalized]
        strategy.intensity = Decimal(80) / 100
        strategy.floor = Decimal(35) / 100
        strategy.excludedTerritoryIDs = ["JPN"]
        return strategy
    }

    private static var customIndexStrategy: PricingStrategy {
        var strategy = customStrategy
        strategy.indexSource = .custom
        return strategy
    }

    @MainActor
    private static func scene(
        app: StoreApp.ID = AppIDs.lumen,
        services pricing: DebugPricingServices? = nil,
        launch: PricingDebugLaunch? = nil,
        pricingModes: [StoreApp.ID: PricingMode] = DebugWorkspace.pricingModes,
        pushRecords: [PushRecord] = DebugWorkspace.pushRecords
    ) -> AnyView {
        var services = WorkspaceServices.debug
        var pricingServices = pricing ?? DebugPricingServices()
        if let launch { pricingServices.launch = launch }
        services.pricing = pricingServices
        return AnyView(DebugMainScene(
            services: services, selectedAppID: app, section: .subscriptionPricing, pushRecords: pushRecords, pricingModes: pricingModes
        ))
    }
}
#endif
