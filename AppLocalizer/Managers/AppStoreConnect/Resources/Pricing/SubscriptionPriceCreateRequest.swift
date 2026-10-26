//
//  SubscriptionPriceCreateRequest.swift
//  AppLocalizer
//

import Foundation

/// The body of `POST /v1/subscriptionPrices`: one territory's new price
/// point for a subscription, starting as soon as Apple processes it.
/// `preserveCurrentPrice` keeps existing subscribers on what they pay today.
struct SubscriptionPriceCreateRequest: Codable, Hashable, Sendable {
    var data: Payload

    struct Payload: Codable, Hashable, Sendable {
        var type = "subscriptionPrices"
        var attributes: Attributes
        var relationships: Relationships
    }

    struct Attributes: Codable, Hashable, Sendable {
        var preserveCurrentPrice: Bool
        var startDate: String?
    }

    struct Relationships: Codable, Hashable, Sendable {
        var subscription: Link
        var territory: Link
        var subscriptionPricePoint: Link
    }

    struct Link: Codable, Hashable, Sendable {
        var data: PricingAPIIdentifier
    }

    init(subscriptionID: String, territoryID: String, pricePointID: String, preserveCurrentPrice: Bool = true, startDate: String? = nil) {
        data = Payload(
            attributes: Attributes(preserveCurrentPrice: preserveCurrentPrice, startDate: startDate),
            relationships: Relationships(
                subscription: Link(data: PricingAPIIdentifier(type: "subscriptions", id: subscriptionID)),
                territory: Link(data: PricingAPIIdentifier(type: "territories", id: territoryID)),
                subscriptionPricePoint: Link(data: PricingAPIIdentifier(type: "subscriptionPricePoints", id: pricePointID))
            )
        )
    }

    var pricePointID: String { data.relationships.subscriptionPricePoint.data.id }
}
