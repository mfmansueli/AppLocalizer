//
//  ProPlan.swift
//  AppLocalizer
//

import Foundation

/// The three ways to buy AppLocalizer Pro. Yearly and Monthly renew, in
/// one subscription group; Lifetime is bought once.
enum ProPlan: String, CaseIterable, Hashable, Sendable, Identifiable {
    case yearly
    case monthly
    case lifetime

    var id: String { rawValue }

    /// The product's identifier in App Store Connect.
    var productID: String {
        switch self {
        case .yearly: "pro.yearly"
        case .monthly: "pro.monthly"
        case .lifetime: "pro.lifetime"
        }
    }

    init?(productID: String) {
        guard let plan = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
        self = plan
    }

    var title: String {
        switch self {
        case .yearly: String(localized: "Yearly")
        case .monthly: String(localized: "Monthly")
        case .lifetime: String(localized: "Lifetime")
        }
    }

    var renews: Bool { self != .lifetime }
}
