//
//  Commission.swift
//  AppLocalizer
//

import Foundation

/// Apple's commission, which proceeds are taken after: 15% in the Small
/// Business Program (the default, switchable in Settings) or 30%.
enum Commission: String, CaseIterable, Codable, Hashable, Sendable {
    case smallBusiness
    case standard

    /// 0.15 or 0.30.
    var rate: Decimal {
        switch self {
        case .smallBusiness: Decimal(15) / 100
        case .standard: Decimal(30) / 100
        }
    }

    var title: String {
        switch self {
        case .smallBusiness: "15% (Small Business Program)"
        case .standard: "30%"
        }
    }

    /// customer price ÷ (1 + tax) × (1 − commission), unrounded.
    func proceeds(customerPrice: Decimal, taxRate: Decimal) -> Decimal {
        customerPrice / (1 + taxRate) * (1 - rate)
    }

    /// The customer price that leaves `proceeds` after tax and commission.
    func customerPrice(forProceeds proceeds: Decimal, taxRate: Decimal) -> Decimal {
        proceeds * (1 + taxRate) / (1 - rate)
    }
}
