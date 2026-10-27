//
//  PriceChangeOrigin.swift
//  AppLocalizer
//

import Foundation

/// Who proposed a price change.
enum PriceChangeOrigin: Hashable, Sendable {
    /// A suggestion applied, or Apply Recommended Prices.
    case recommended
    /// The stepper, a nearby point, a bulk action or "Use this".
    case manual
    /// A custom strategy.
    case custom
}
