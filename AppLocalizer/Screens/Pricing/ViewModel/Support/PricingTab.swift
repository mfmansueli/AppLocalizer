//
//  PricingTab.swift
//  AppLocalizer
//

import Foundation

/// The section bar's Prices | Offers | Results. In-app purchases have no
/// offers.
enum PricingTab: String, CaseIterable, Hashable, Sendable {
    case prices
    case offers
    case results

    var title: String {
        switch self {
        case .prices: String(localized: "Prices")
        case .offers: String(localized: "Offers")
        case .results: String(localized: "Results")
        }
    }
}
