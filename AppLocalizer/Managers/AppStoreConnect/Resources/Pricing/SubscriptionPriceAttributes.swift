//
//  SubscriptionPriceAttributes.swift
//  AppLocalizer
//

import Foundation

/// The fields AppLocalizer reads from a `subscriptionPrices` resource. A nil
/// `startDate` is the price the subscription started with.
struct SubscriptionPriceAttributes: Decodable, Sendable {
    var startDate: String?
    var preserved: Bool?
}
