//
//  OfferPricingTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("OfferPricing")
struct OfferPricingTests {
    private let sample = PricingFixtures.sample

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private func offer(_ id: String) throws -> SubscriptionOffer {
        try #require(PricingSampleData.offers.first { $0.id == id })
    }

    @Test(arguments: [("BR", "R$ 109,90", "R$ 93,42"), ("JP", "¥3,000", "¥2,318"), ("MX", "MX$ 269.00", "MX$ 197.11"), ("US", "$19.99", "$16.99")])
    func promotionalOfferIsHalfTheTerritorysPrice(example: (code: String, price: String, proceeds: String)) throws {
        let territory = try PricingFixtures.territory(example.code)
        let price = try sample.offerPrice(offer("promo"), in: territory)
        let point = try #require(price.offerPrice)
        let proceeds = try #require(price.proceeds)
        #expect(!price.isFree)
        #expect(CurrencyFormat.format(point.customerPrice, currency: territory.currencyCode) == example.price)
        #expect(CurrencyFormat.format(proceeds, currency: territory.currencyCode) == example.proceeds)
    }

    @Test func offersStartFromTodaysPrice() throws {
        let mexico = try sample.offerPrice(offer("promo"), in: PricingFixtures.territory("MX"))
        #expect(mexico.subscriptionPrice == 549)
    }

    @Test func winBackIsAQuarterOfTheAnnualPrice() throws {
        let price = try sample.offerPrice(offer("winback"), in: PricingFixtures.territory("BR"))
        #expect(price.offerPrice?.customerPrice == money("54.90"))
    }

    @Test(arguments: ["intro", "codes"])
    func freeTrialsHaveNoPrice(id: String) throws {
        let price = try sample.offerPrice(offer(id), in: PricingFixtures.territory("BR"))
        #expect(price.isFree)
        #expect(price.proceeds == nil)
    }

    @Test func sampleOffersCoverEveryKind() {
        #expect(PricingSampleData.offers.map(\.kind) == OfferKind.allCases)
        #expect(OfferKind.winBack.groupTitle == "Win-back offers")
        #expect(OfferKind.offerCode.title == "Offer code")
        #expect(OfferPaymentMode.payUpFront.title == "Pay up front")
    }

    @Test func emptyLadderMeansNoOfferPrice() throws {
        let brazil = try PricingFixtures.territory("BR")
        let price = try OfferPricing.price(
            offer("promo"),
            subscriptionPrice: money("219.90"),
            territory: brazil,
            ladder: PricingFixtures.ladder([], currency: "BRL", territoryID: "BRA")
        )
        #expect(price.isFree)
    }
}
