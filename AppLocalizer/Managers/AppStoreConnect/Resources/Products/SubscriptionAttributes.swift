//
//  SubscriptionAttributes.swift
//  AppLocalizer
//

import Foundation

/// The fields AppLocalizer reads from a `subscriptions` resource.
struct SubscriptionAttributes: Decodable, Sendable {
    var name: String
    var productId: String
    var state: String?
    var subscriptionPeriod: String?
}
