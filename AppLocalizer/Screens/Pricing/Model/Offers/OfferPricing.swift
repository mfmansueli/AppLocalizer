//
//  OfferPricing.swift
//  AppLocalizer
//

import Foundation

/// Derives offer prices from each territory's subscription price, snapped to
/// its price points, so when a territory's price drops its offer drops too.
enum OfferPricing {
    static func price(
        _ offer: SubscriptionOffer,
        subscriptionPrice: Decimal,
        territory: Territory,
        ladder: PricePointLadder,
        commission: Commission = .smallBusiness
    ) -> OfferPrice {
        let target = subscriptionPrice * offer.priceShare
        guard offer.paymentMode != .freeTrial, target > 0, let point = ladder.nearest(to: target, rounding: .auto) else {
            return OfferPrice(territory: territory, subscriptionPrice: subscriptionPrice, offerPrice: nil, proceeds: nil)
        }
        let proceeds = commission.proceeds(customerPrice: point.customerPrice, taxRate: territory.taxRate)
        return OfferPrice(territory: territory, subscriptionPrice: subscriptionPrice, offerPrice: point, proceeds: proceeds)
    }
}
