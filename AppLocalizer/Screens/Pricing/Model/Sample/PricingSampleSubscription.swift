//
//  PricingSampleSubscription.swift
//  AppLocalizer
//

import Foundation

/// Lumen Journal's products in the sample world.
enum PricingSampleSubscription: String, CaseIterable, Hashable, Sendable {
    case monthly
    case annual
    /// A non-consumable in-app purchase: same matrix, no offers.
    case lifetime

    /// The base (United States) price.
    var basePrice: Decimal {
        switch self {
        case .monthly: Decimal(499) / 100
        case .annual: Decimal(3999) / 100
        case .lifetime: Decimal(7999) / 100
        }
    }

    var name: String {
        switch self {
        case .monthly: "Lumen Plus Monthly"
        case .annual: "Lumen Plus Annual"
        case .lifetime: "Lumen Lifetime"
        }
    }

    var productID: String {
        switch self {
        case .monthly: "lumen.plus.monthly"
        case .annual: "lumen.plus.annual"
        case .lifetime: "lumen.lifetime"
        }
    }

    var duration: String {
        switch self {
        case .monthly: "1 month"
        case .annual: "1 year"
        case .lifetime: "Non-consumable"
        }
    }

    var isInAppPurchase: Bool { self == .lifetime }
}
