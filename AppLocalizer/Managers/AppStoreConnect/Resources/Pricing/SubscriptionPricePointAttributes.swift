//
//  SubscriptionPricePointAttributes.swift
//  AppLocalizer
//

import Foundation

/// The fields AppLocalizer reads from a `subscriptionPricePoints` resource.
/// Apple sends amounts as decimal strings (“39.99”); `proceedsYear2` is what
/// you earn after a subscriber's first year, at the 15% rate.
struct SubscriptionPricePointAttributes: Decodable, Sendable {
    var customerPrice: String?
    var proceeds: String?
    var proceedsYear2: String?
}
