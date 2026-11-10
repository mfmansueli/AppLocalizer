//
//  PricingDebugLaunch.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The state a Pricing DEBUG scene opens in, reached through the same view
/// model calls a person's clicks make: filters, selection, applied prices,
/// the inspector, an open popover or sheet, and the tab and view shown.
struct PricingDebugLaunch {
    /// Opens on the product cards instead of the selected product's matrix.
    var showsProducts = false
    /// Selects this product instead of the default one.
    var productID: String?
    var region: TerritoryRegion?
    /// Territories (alpha-3) whose suggestion is applied.
    var appliedSuggestions: [String] = []
    /// Follow the strategy everywhere, as Apply Recommended Prices… does, without opening review.
    var follows = false
    /// Hand-set prices by territory (alpha-3).
    var manualPrices: [String: Decimal] = [:]
    var strategy: PricingStrategy?
    var selection: [String] = []
    var popover: PricingPopover?
    /// Opens the inspector on this tab.
    var inspectorTab: StrategyInspectorTab?
    var collapsedSections: Set<StrategyInspectorSection> = []
    /// Opens the custom index import sheet with the sample CSV.
    var showsImport = false
    /// Refreshes once loaded, as ⌘R does.
    var refreshes = false
    var tab: PricingTab?
    var display: PricingDisplay?
    /// The tile map's hovered territory (alpha-3).
    var hoveredTerritory: String?
    /// The schedule queued changes follow.
    var schedule: PriceSchedule?
    /// Opens the schedule sheet.
    var showsSchedule = false
    /// Selects this offer on the Offers tab.
    var offerID: SubscriptionOffer.ID?
    /// Pins today, for Results' 28 days and the schedule's earliest date.
    var today: Date?
}
#endif
