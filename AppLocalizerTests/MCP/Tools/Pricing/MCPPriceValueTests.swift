//
//  MCPPriceValueTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("MCPPriceValue")
struct MCPPriceValueTests {
    @Test func wholeAmountsAreIntegers() {
        #expect(MCPPriceValue.json(PricingFixtures.money("2499")) == .int(2499))
        #expect(MCPPriceValue.json(PricingFixtures.money("39.00")) == .int(39))
        #expect(MCPPriceValue.json(PricingFixtures.money("219.90")) == .double(219.9))
    }

    @Test func numbersAndNumericStringsAreRead() {
        #expect(MCPPriceValue.decimal(from: .double(109.9)) == PricingFixtures.money("109.9"))
        #expect(MCPPriceValue.decimal(from: .int(999)) == PricingFixtures.money("999"))
        #expect(MCPPriceValue.decimal(from: "109.90") == PricingFixtures.money("109.9"))
        #expect(MCPPriceValue.decimal(from: " 109,90 ") == PricingFixtures.money("109.9"))
    }

    @Test(arguments: [JSONValue.string("R$ 109,90"), "", "1.234,56", .int(0), .double(-5), .bool(true), .null, .double(.infinity)])
    func anythingElseIsNotAPrice(_ value: JSONValue) {
        #expect(MCPPriceValue.decimal(from: value) == nil)
    }
}
