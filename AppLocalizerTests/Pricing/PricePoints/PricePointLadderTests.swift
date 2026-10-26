//
//  PricePointLadderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PricePointLadder")
struct PricePointLadderTests {
    /// Unsorted, with a duplicate and a few points off the .99 grid.
    private let ladder = PricingFixtures.ladder(["9.99", "4.99", "5.49", "5.99", "6.49", "5.99", "7.00", "7.99", "8.99", "10.00", "10.99"])

    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    @Test func sortsAndDropsDuplicatePrices() {
        let expected = ["4.99", "5.49", "5.99", "6.49", "7", "7.99", "8.99", "9.99", "10", "10.99"].map(money)
        #expect(PricingFixtures.prices(ladder.points) == expected)
    }

    @Test func findsExactPointsOnly() {
        #expect(ladder.point(at: money("5.99"))?.customerPrice == money("5.99"))
        #expect(ladder.point(at: 6) == nil)
    }

    @Test func nearestIgnoresTheEndingAndBreaksTiesUpward() {
        #expect(ladder.nearest(to: money("6.2"))?.customerPrice == money("5.99"))
        let tie = PricingFixtures.ladder(["4.00", "6.00"])
        #expect(tie.nearest(to: 5)?.customerPrice == 6)
    }

    @Test func roundingPrefersThePointWithTheEnding() {
        #expect(ladder.nearest(to: money("7.2"), rounding: .auto)?.customerPrice == money("6.49"))
        #expect(ladder.nearest(to: money("7.2"), rounding: .round)?.customerPrice == 7)
        #expect(ladder.nearest(to: money("9.8"), rounding: .round)?.customerPrice == 10)
    }

    @Test func lowestAtOrAboveNeverRoundsDown() {
        #expect(ladder.lowest(atOrAbove: money("6.1"), rounding: .auto)?.customerPrice == money("6.49"))
        #expect(ladder.lowest(atOrAbove: money("5.99"), rounding: .auto)?.customerPrice == money("5.99"))
        #expect(ladder.lowest(atOrAbove: 20, rounding: .auto)?.customerPrice == money("10.99"))
    }

    @Test func stepsWalkPointsWithTheEnding() {
        #expect(ladder.step(from: money("6.2"), by: 1, rounding: .auto)?.customerPrice == money("6.49"))
        #expect(ladder.step(from: money("6.2"), by: -1, rounding: .auto)?.customerPrice == money("5.99"))
        #expect(ladder.step(from: money("6.49"), by: 1, rounding: .auto)?.customerPrice == money("7.99"))
        #expect(ladder.step(from: money("5.99"), by: 10, rounding: .auto)?.customerPrice == money("10.99"))
        #expect(ladder.step(from: money("4.99"), by: -1, rounding: .auto) == nil)
    }

    @Test func nearbyPutsThePriceInTheMiddleWhenItIsAPoint() {
        let onPoint = ladder.nearby(money("7.99"), count: 2, rounding: .auto)
        #expect(PricingFixtures.prices(onPoint) == ["5.99", "6.49", "7.99", "8.99", "9.99"].map(money))
        let between = ladder.nearby(money("7.5"), count: 2, rounding: .auto)
        #expect(PricingFixtures.prices(between) == ["5.99", "6.49", "7.99", "8.99"].map(money))
    }

    @Test func emptyLadderFindsNothing() {
        let empty = PricingFixtures.ladder([])
        #expect(empty.isEmpty)
        #expect(empty.nearest(to: 5) == nil)
        #expect(empty.nearest(to: 5, rounding: .auto) == nil)
        #expect(empty.lowest(atOrAbove: 5, rounding: .auto) == nil)
        #expect(empty.nearby(5, rounding: .auto).isEmpty)
    }

    // MARK: - Simulated Brazil ladder

    @Test func brazilSnapsToCommaNinety() throws {
        let ladder = try PricingFixtures.sample.ladder(for: PricingFixtures.territory("BR"))
        #expect(ladder.nearest(to: money("109.95"), rounding: .auto)?.customerPrice == money("109.90"))
        #expect(ladder.nearest(to: money("175.92"), rounding: .auto)?.customerPrice == money("174.90"))
        #expect(ladder.nearest(to: money("164.925"), rounding: .auto)?.customerPrice == money("164.90"))
    }

    @Test func brazilNearbyChips() throws {
        let ladder = try PricingFixtures.sample.ladder(for: PricingFixtures.territory("BR"))
        let around109 = ladder.nearby(money("109.90"), rounding: .auto)
        #expect(PricingFixtures.prices(around109) == ["98.90", "99.90", "104.90", "109.90", "114.90", "119.90", "124.90"].map(money))
        let around174 = ladder.nearby(money("174.90"), rounding: .auto)
        #expect(PricingFixtures.prices(around174) == ["159.90", "164.90", "169.90", "174.90", "179.90", "184.90", "189.90"].map(money))
    }

    @Test func simulatedPointsCarryProceedsAfterTaxAndCommission() throws {
        let brazil = try PricingFixtures.territory("BR")
        let point = try #require(PricingFixtures.sample.ladder(for: brazil).point(at: money("109.90")))
        #expect(point.proceeds == money("93.42"))
        #expect(point.appStoreConnectID == nil)
    }

    @Test func simulatedLaddersCoverTheDollarRange() throws {
        let brazil = try PricingFixtures.territory("BR")
        let ladder = SimulatedPriceLadder.make(territory: brazil, equalizationMultiplier: money("5.5"))
        let first = try #require(ladder.points.first?.customerPrice)
        let last = try #require(ladder.points.last?.customerPrice)
        #expect(first <= money("1.6"))
        #expect(last == 5500)
        #expect(ladder.points.count > 800)
    }
}
