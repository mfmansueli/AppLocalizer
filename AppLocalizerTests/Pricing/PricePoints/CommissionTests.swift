//
//  CommissionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("Commission")
struct CommissionTests {
    @Test func ratesAndTitles() {
        #expect(Commission.smallBusiness.rate == PricingFixtures.money("0.15"))
        #expect(Commission.standard.rate == PricingFixtures.money("0.3"))
        #expect(Commission.smallBusiness.title == "15% (Small Business Program)")
    }

    @Test func proceedsTakeOffTaxThenCommission() {
        let price = PricingFixtures.money("39.99")
        #expect(Commission.smallBusiness.proceeds(customerPrice: price, taxRate: 0) == PricingFixtures.money("33.9915"))
        let germany = Commission.standard.proceeds(customerPrice: 119, taxRate: PricingFixtures.money("0.19"))
        #expect(germany == 70)
    }

    @Test func customerPriceForProceedsIsTheInverse() {
        let tax = PricingFixtures.money("0.2")
        let price = Commission.smallBusiness.customerPrice(forProceeds: 17, taxRate: tax)
        #expect(price == 24)
        #expect(Commission.smallBusiness.proceeds(customerPrice: price, taxRate: tax) == 17)
    }
}
