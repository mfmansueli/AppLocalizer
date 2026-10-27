//
//  PricingMethod.swift
//  AppLocalizer
//

import Foundation

/// How a strategy turns Apple's equalized price into a proposed one.
enum PricingMethod: String, CaseIterable, Codable, Hashable, Sendable {
    /// World Bank PPP at full intensity, 30% floor, discounts only.
    case recommended
    /// Apple's equalized price as is: currency and tax conversion only.
    case equalized
    /// A chosen price index with the inspector's settings.
    case priceIndex
    /// One multiplier per region.
    case regionalTiers

    var title: String {
        switch self {
        case .recommended: "Recommended"
        case .equalized: "Apple equalization"
        case .priceIndex: "Price index"
        case .regionalTiers: "Custom regional tiers"
        }
    }

    var summary: String {
        switch self {
        case .recommended:
            "World Bank PPP at full intensity, 30% floor, discounts only. Your sales adjust confidence and step size."
        case .equalized: "Currency and tax conversion only."
        case .priceIndex: "Choose a source and tune it below."
        case .regionalTiers: "One multiplier per region."
        }
    }
}
