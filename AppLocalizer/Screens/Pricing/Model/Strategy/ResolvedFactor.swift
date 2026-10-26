//
//  ResolvedFactor.swift
//  AppLocalizer
//

import Foundation

/// A territory's price level relative to the base territory, and where it
/// came from.
struct ResolvedFactor: Hashable, Sendable {
    var factor: Decimal
    var provenance: PriceProvenance
}
