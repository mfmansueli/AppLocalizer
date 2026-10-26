//
//  OfferPrice.swift
//  AppLocalizer
//

import Foundation

/// An offer's price in one territory.
struct OfferPrice: Hashable, Sendable, Identifiable {
    var territory: Territory
    var subscriptionPrice: Decimal
    /// Nil for a free trial ("Free").
    var offerPrice: PricePoint?
    /// "You receive": the offer price after tax and commission; nil when free.
    var proceeds: Decimal?

    var id: String { territory.id }

    var isFree: Bool { offerPrice == nil }
}
