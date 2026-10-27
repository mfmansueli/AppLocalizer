//
//  PriceChange.swift
//  AppLocalizer
//

import Foundation

/// The move from one price to another, for the Change column's pill.
struct PriceChange: Hashable, Sendable {
    enum Direction: Hashable, Sendable {
        case increase
        case decrease
        case none
    }

    var old: Decimal
    var new: Decimal

    /// Whether the prices differ (by more than a thousandth).
    var isChanged: Bool { (new - old).magnitude > Decimal(1) / 1000 }

    var direction: Direction {
        guard isChanged else { return .none }
        return new > old ? .increase : .decrease
    }

    /// Whole percent, signed, rounded like the prototype (halves up):
    /// R$ 219,90 → R$ 109,90 is −50.
    var percent: Int {
        guard old != 0 else { return 0 }
        let value = ((new / old - 1) * 100).doubleValue
        return Int((value + 0.5).rounded(.down))
    }

    /// "−50%", "+18%", "0%" (minus is U+2212).
    var percentText: String { PricingText.signedPercent(percent) }

    /// The pill: "▼ −50%", "▲ +18%"; empty when unchanged.
    var pillText: String {
        switch direction {
        case .increase: "▲ " + percentText
        case .decrease: "▼ " + percentText
        case .none: ""
        }
    }
}
