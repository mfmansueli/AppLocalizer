//
//  PricingSheetError.swift
//  AppLocalizer
//

import Foundation

/// Why a product's prices can't be shown, when it's a state Pricing offers
/// a way out of rather than a failure.
enum PricingSheetError: LocalizedError, Hashable, Sendable {
    /// A subscription made without prices (in App Store Connect, or one
    /// whose starting price couldn't be set): Pricing offers Set Starting
    /// Price.
    case noStartingPrice(productName: String)

    var errorDescription: String? {
        switch self {
        case let .noStartingPrice(name): String(localized: "\(name) has no price in the United States yet.")
        }
    }
}
