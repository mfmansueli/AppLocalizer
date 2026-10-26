//
//  PricingSampleData+Offers.swift
//  AppLocalizer
//

import Foundation

extension PricingSampleData {
    /// Lumen Plus Annual's offers in the prototype.
    static let offers: [SubscriptionOffer] = [
        SubscriptionOffer(
            id: "intro",
            kind: .introductory,
            name: "1 week free",
            eligibility: "New subscribers · Annual",
            paymentMode: .freeTrial,
            duration: "1 week",
            rule: "Free for 1 week, then the territory’s Annual price",
            priceShare: 0
        ),
        SubscriptionOffer(
            id: "promo",
            kind: .promotional,
            name: "50% off the first year",
            eligibility: "Lapsed subscribers · Annual",
            paymentMode: .payUpFront,
            duration: "1 year",
            rule: "50% of each territory’s price, snapped to the nearest price point",
            priceShare: Decimal(1) / 2
        ),
        SubscriptionOffer(
            id: "winback",
            kind: .winBack,
            name: "3 months at $9.99",
            eligibility: "Churned 60+ days ago · Annual",
            paymentMode: .payUpFront,
            duration: "3 months",
            rule: "25% of each territory’s Annual price, snapped",
            priceShare: Decimal(1) / 4
        ),
        SubscriptionOffer(
            id: "codes",
            kind: .offerCode,
            name: "PRESS2026 · 1 month free",
            eligibility: "500 one-time codes · expires Dec 31",
            paymentMode: .freeTrial,
            duration: "1 month",
            rule: "Free for 1 month",
            priceShare: 0
        ),
    ]

    /// An offer's price in a territory, from today's subscription price.
    func offerPrice(_ offer: SubscriptionOffer, in territory: Territory, subscription: PricingSampleSubscription = .annual) -> OfferPrice {
        OfferPricing.price(
            offer,
            subscriptionPrice: currentPrice(for: territory, subscription: subscription),
            territory: territory,
            ladder: ladder(for: territory),
            commission: commission
        )
    }
}
