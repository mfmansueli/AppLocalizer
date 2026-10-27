//
//  PricingPopover.swift
//  AppLocalizer
//

import Foundation

/// The popover open on a matrix row, if any: why a price is suggested, or
/// how the proposed price breaks down.
enum PricingPopover: Hashable, Sendable {
    case suggestion(PricingRow.ID)
    case breakdown(PricingRow.ID)

    var rowID: PricingRow.ID {
        switch self {
        case let .suggestion(id), let .breakdown(id): id
        }
    }
}
