//
//  ProGateTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ProGate")
struct ProGateTests {
    @Test func withProTheActionRuns() {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore(), override: true))
        var ran = 0
        gate.require(.autopilot) { ran += 1 }
        #expect(ran == 1)
        #expect(gate.paywall == nil)
        #expect(!gate.isFree)
    }

    @Test func inFreeThePaywallOpensWithWhatWasBlocked() {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore()))
        var ran = 0
        gate.require(.recommendedPrices(countries: 104)) { ran += 1 }
        #expect(ran == 0)
        #expect(gate.paywall?.context == .recommendedPrices(countries: 104))
        #expect(gate.isFree)
    }

    @Test func afterBuyingContinueFinishesWhatWasStarted() async throws {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore()))
        var ran = 0
        gate.require(.autopilot) { ran += 1 }
        let paywall = try #require(gate.paywall)
        await paywall.load()
        await paywall.buy()
        gate.finish(paywall, continues: true)
        #expect(ran == 1)
        #expect(gate.paywall == nil)
    }

    @Test func closingWithoutBuyingRunsNothing() throws {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore()))
        var ran = 0
        gate.require(.retention) { ran += 1 }
        let paywall = try #require(gate.paywall)
        gate.finish(paywall, continues: true)
        #expect(ran == 0, "Continue without Pro does nothing")
        gate.require(.retention) { ran += 1 }
        try gate.finish(#require(gate.paywall), continues: false)
        #expect(ran == 0)
    }

    @Test func theToolbarOpensThePlansWithNoCard() {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore()))
        gate.showPlans()
        #expect(gate.paywall?.context == .menu)
        #expect(gate.paywall?.continueTitle == nil)
    }

    @Test func freeWorksOnTheFirstAppOpened() throws {
        let defaults = try #require(UserDefaults(suiteName: "ProGateTests.\(UUID().uuidString)"))
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore()), defaults: defaults)
        #expect(gate.mayOpen(appID: "1"))
        #expect(gate.mayOpen(appID: "1"))
        #expect(!gate.mayOpen(appID: "2"))
        // The same app at the next launch.
        let later = ProGate(entitlements: Entitlements(store: FakeProStore()), defaults: defaults)
        #expect(later.freeAppID == "1")
        #expect(!later.mayOpen(appID: "2"))
    }

    @Test func proOpensEveryApp() {
        let gate = ProGate(entitlements: Entitlements(store: FakeProStore(), override: true))
        #expect(gate.mayOpen(appID: "1"))
        #expect(gate.mayOpen(appID: "2"))
        #expect(gate.freeAppID == nil, "Pro doesn’t pick a free app")
    }

    @Test func withoutAGateEverythingRuns() {
        let gate: ProGate? = nil
        var ran = 0
        gate.require(.autopilot) { ran += 1 }
        #expect(ran == 1)
        #expect(!gate.isFree)
    }
}
