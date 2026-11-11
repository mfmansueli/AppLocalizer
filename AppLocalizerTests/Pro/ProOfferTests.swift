//
//  ProOfferTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ProOffer")
struct ProOfferTests {
    private let yearly = FakeProStore.usOffers[0]
    private let monthly = FakeProStore.usOffers[1]
    private let lifetime = FakeProStore.usOffers[2]

    @Test func theButtonSaysExactlyWhatHappens() {
        #expect(yearly.callToAction == "Start 7-Day Free Trial")
        #expect(monthly.callToAction == "Subscribe for $9.99 a Month")
        #expect(lifetime.callToAction == "Buy Pro for $149.99")
    }

    /// Someone who already had the trial subscribes right away.
    @Test func withoutATrialYearlySubscribes() {
        var offer = yearly
        offer.trialDays = nil
        #expect(offer.callToAction == "Subscribe for $59.99 a Year")
        #expect(offer.subtitle == "$5.00 a month")
        #expect(offer.finePrint.hasPrefix("$59.99 a year. Renews automatically"))
    }

    @Test func eachPlanSaysWhatItCostsAndHowOften() {
        #expect(yearly.subtitle == "$5.00 a month · 7 days free")
        #expect(yearly.period == "/ year")
        #expect(monthly.subtitle == "Cancel anytime")
        #expect(monthly.period == "/ month")
        #expect(lifetime.subtitle == "Pay once, Pro forever")
        #expect(lifetime.period == "once")
    }

    /// The full price, the period and how renewal works: guideline 3.1.2.
    @Test func theFinePrintHasThePriceThePeriodAndRenewal() {
        #expect(yearly.finePrint.hasPrefix("Free for 7 days, then $59.99 a year."))
        #expect(yearly.finePrint.contains("Renews automatically until you cancel, at least 24 hours before the end of the period"))
        #expect(monthly.finePrint.hasPrefix("$9.99 a month. Renews automatically"))
        #expect(lifetime.finePrint.hasPrefix("One payment."))
        #expect(!lifetime.finePrint.contains("Renews"))
    }

    @Test func yearlySavesHalfAgainstTwelveMonths() {
        #expect(ProOffer.savings(yearly: yearly, monthly: monthly) == "Save 50%")
    }

    @Test func noSavingIsClaimedWithoutBothPricesOrWhenItsSmall() {
        #expect(ProOffer.savings(yearly: yearly, monthly: nil) == nil)
        #expect(ProOffer.savings(yearly: nil, monthly: monthly) == nil)
        let dear = ProOffer(plan: .yearly, displayPrice: "$117.00", price: 117)
        #expect(ProOffer.savings(yearly: dear, monthly: monthly) == nil)
    }

    @Test func plansAreFoundByTheirProduct() {
        #expect(ProPlan(productID: "pro.yearly") == .yearly)
        #expect(ProPlan(productID: "pro.monthly") == .monthly)
        #expect(ProPlan(productID: "pro.lifetime") == .lifetime)
        #expect(ProPlan(productID: "pro.weekly") == nil)
        #expect(ProPlan.allCases.filter(\.renews) == [.yearly, .monthly])
    }
}
