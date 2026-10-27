//
//  AppSorter.swift
//  AppLocalizer
//

import Foundation

/// Orders the sidebar's apps by the sort menu's choice. Ties, and apps whose
/// indicator isn't known yet, fall back to name order.
enum AppSorter {
    static func sort(_ apps: [StoreApp], by order: AppSortOrder, indicators: (StoreApp) -> AppIndicators) -> [StoreApp] {
        let byName = apps.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        switch order {
        case .name:
            return byName
        case .unpushedChanges:
            return byName.stableSorted { indicators($0).pendingChangeCount > indicators($1).pendingChangeCount }
        case .lowestCoverage:
            return byName.stableSorted { (indicators($0).localeCount ?? .max) < (indicators($1).localeCount ?? .max) }
        case .mostSuggestions:
            return byName.stableSorted { (indicators($0).priceSuggestionCount ?? -1) > (indicators($1).priceSuggestionCount ?? -1) }
        }
    }
}

private extension Array {
    /// `sorted(by:)` that keeps the existing order of equal elements.
    func stableSorted(by areInIncreasingOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated()
            .sorted { lhs, rhs in
                if areInIncreasingOrder(lhs.element, rhs.element) { return true }
                if areInIncreasingOrder(rhs.element, lhs.element) { return false }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}
