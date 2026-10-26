//
//  PriceEnding.swift
//  AppLocalizer
//

import Foundation

/// A currency's usual price ending ("Snapping" in the design README). Raw
/// values are the design prototype's codes.
enum PriceEnding: String, CaseIterable, Codable, Hashable, Sendable {
    /// `$39.99`, `39,99 €`, `£35.99`.
    case ninetyNine = "d99"
    /// `R$ 219,90`, `S/ 149.90`.
    case ninety = "d90"
    /// `S$ 54.98`.
    case ninetyEight = "d98"
    /// `CHF 40.00`.
    case wholeUnits = "d00"
    /// Round numbers in currencies without decimals: `¥6,000`, `₩56,000`.
    case round = "r"
    /// A 9 after two leading digits: `MX$ 549.00`, `Rp 639.000`, `439,00 kr`.
    case nineAfterTwoDigits = "k2"
    /// A 9 after three leading digits: `₹3,399`, `COP 164.900`.
    case nineAfterThreeDigits = "k3"
    /// An 8 in Chinese-speaking markets: `CN¥288.00`, `HK$ 318.00`.
    case eight = "e8"

    /// The leading digits before the 9, for the two "nine" endings.
    var leadingDigits: Int? {
        switch self {
        case .nineAfterTwoDigits: 2
        case .nineAfterThreeDigits: 3
        default: nil
        }
    }
}
