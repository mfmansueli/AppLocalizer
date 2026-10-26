//
//  PriorPriceChange.swift
//  AppLocalizer
//

import Foundation

/// An earlier price change in a territory and the starts 28 days either side.
/// Its presence makes a suggestion High confidence.
struct PriorPriceChange: Hashable, Sendable {
    var date: Date
    /// The price before the change; the current price is the one after.
    var previousPrice: Decimal
    var before: SalesSignal
    var after: SalesSignal

    /// Whether the change brought more starts.
    var liftedStarts: Bool { after.starts > before.starts }
}
