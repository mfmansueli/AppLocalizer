//
//  PricingPage.swift
//  AppLocalizer
//

import Foundation

/// Pricing's two pages: the subscription prices, and the retention
/// messages and offers people see when they cancel.
enum PricingPage: String, CaseIterable, Identifiable, Sendable {
    case prices
    case retention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prices: String(localized: "Prices")
        case .retention: String(localized: "Retention")
        }
    }
}
