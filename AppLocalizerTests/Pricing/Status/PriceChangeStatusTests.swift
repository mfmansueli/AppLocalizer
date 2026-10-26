//
//  PriceChangeStatusTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PriceChange and PriceChangeStatus")
struct PriceChangeStatusTests {
    private func money(_ text: String) -> Decimal {
        PricingFixtures.money(text)
    }

    private var cut: PriceChange {
        PriceChange(old: money("219.90"), new: money("109.90"))
    }

    @Test func percentRoundsHalvesUp() {
        #expect(cut.percent == -50)
        #expect(cut.percentText == "−50%")
        #expect(PriceChange(old: 100, new: money("118.4")).percent == 18)
        #expect(PriceChange(old: 100, new: money("100.5")).percent == 1)
        #expect(PriceChange(old: 100, new: money("99.5")).percent == 0)
        #expect(PriceChange(old: 0, new: 5).percent == 0)
    }

    @Test func pillsShowTheDirection() {
        #expect(cut.direction == .decrease)
        #expect(cut.pillText == "▼ −50%")
        let raise = PriceChange(old: 100, new: 118)
        #expect(raise.direction == .increase)
        #expect(raise.pillText == "▲ +18%")
        let same = PriceChange(old: money("39.99"), new: money("39.9905"))
        #expect(!same.isChanged)
        #expect(same.direction == .none)
        #expect(same.pillText.isEmpty)
    }

    @Test func unchangedRowsAreUnchangedOrExcluded() {
        let same = PriceChange(old: 10, new: 10)
        #expect(PriceChangeStatus.resolve(change: same, origin: .manual) == .unchanged)
        #expect(PriceChangeStatus.resolve(change: nil, origin: nil) == .unchanged)
        #expect(PriceChangeStatus.resolve(change: same, origin: nil, isExcluded: true) == .excluded)
    }

    @Test func changedRowsAreNamedByWhoProposedThem() {
        #expect(PriceChangeStatus.resolve(change: cut, origin: .recommended) == .recommended)
        #expect(PriceChangeStatus.resolve(change: cut, origin: .manual) == .editedManually)
        #expect(PriceChangeStatus.resolve(change: cut, origin: .custom) == .custom)
    }

    @Test func scheduledWinsOverTheOrigin() {
        #expect(PriceChangeStatus.resolve(change: cut, origin: .manual, isScheduled: true) == .scheduled)
    }

    @Test func withoutAnOriginItIsAnIncreaseOrDecrease() {
        #expect(PriceChangeStatus.resolve(change: cut, origin: nil) == .decrease)
        #expect(PriceChangeStatus.resolve(change: PriceChange(old: 1, new: 2), origin: nil) == .increase)
    }

    @Test func titlesAndSymbols() {
        #expect(PriceChangeStatus.allCases.count == 8)
        #expect(PriceChangeStatus.editedManually.title == "Edited manually")
        #expect(PriceChangeStatus.unchanged.systemImage == nil)
        #expect(PriceChangeStatus.allCases.filter { $0 != .unchanged }.allSatisfy { $0.systemImage != nil })
    }
}
