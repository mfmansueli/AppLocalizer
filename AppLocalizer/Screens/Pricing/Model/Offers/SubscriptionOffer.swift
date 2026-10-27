//
//  SubscriptionOffer.swift
//  AppLocalizer
//

import Foundation

/// An offer whose price in every territory derives from that territory's
/// subscription price.
struct SubscriptionOffer: Hashable, Sendable, Identifiable {
    var id: String
    var kind: OfferKind
    /// "50% off the first year".
    var name: String
    /// "Lapsed subscribers · Annual".
    var eligibility: String
    var paymentMode: OfferPaymentMode
    /// "1 year", "3 months".
    var duration: String
    /// "50% of each territory’s price, snapped to the nearest price point".
    var rule: String
    /// Share of the subscription price charged: per period for pay as you
    /// go, once for pay up front; ignored for free trials.
    var priceShare: Decimal
}
