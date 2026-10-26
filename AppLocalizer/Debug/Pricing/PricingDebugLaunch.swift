//
//  PricingDebugLaunch.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The state a Pricing DEBUG scene opens in, reached through the same view
/// model calls a person's clicks make: filters, selection, applied prices,
/// the inspector and an open popover or sheet.
struct PricingDebugLaunch {
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
}
#endif
