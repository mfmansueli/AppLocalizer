//
//  PriceAdjustment.swift
//  AppLocalizer
//

import Foundation

/// The limit that decided the price, as the one-line summary says it:
/// "… → above floor → R$ 109,90".
enum PriceAdjustment: Hashable, Sendable {
    /// Apple equalization: nothing applied.
    case kept
    case excluded
    case aboveFloor
    case cappedAtEqualized
    case raisedToFloor
    case loweredToCeiling
    case minimumProceeds
    case neverRaise

    var text: String {
        switch self {
        case .kept: "kept"
        case .excluded: "excluded"
        case .aboveFloor: "above floor"
        case .cappedAtEqualized: "capped at equalized"
        case .raisedToFloor: "raised to floor"
        case .loweredToCeiling: "lowered to ceiling"
        case .minimumProceeds: "min. proceeds"
        case .neverRaise: "never raise"
        }
    }
}
