//
//  EntitlementsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("Entitlements")
struct EntitlementsTests {
    @Test func freeCantUseWhatProAdds() {
        let entitlements = Entitlements(store: FakeProStore())
        #expect(!entitlements.isPro)
        for feature in ProFeature.allCases {
            #expect(!entitlements.canUse(feature))
        }
    }

    @Test func buyingUnlocksEverything() async {
        let store = FakeProStore()
        let entitlements = Entitlements(store: store)
        let outcome = await entitlements.purchase(.lifetime)
        #expect(outcome == .purchased(.lifetime))
        #expect(entitlements.isPro)
        #expect(ProFeature.allCases.allSatisfy(entitlements.canUse))
        #expect(store.purchases == [.lifetime])
    }

    @Test func aCancelledPurchaseLeavesFree() async {
        let store = FakeProStore()
        store.outcome = .cancelled
        let entitlements = Entitlements(store: store)
        #expect(await entitlements.purchase(.yearly) == .cancelled)
        #expect(!entitlements.isPro)
    }

    @Test func whatThePersonOwnsIsReadAtLaunch() async throws {
        let store = FakeProStore()
        store.owned = .subscribed(plan: .monthly, until: nil, isTrial: false)
        let entitlements = Entitlements(store: store)
        entitlements.start()
        for _ in 0..<200 where !entitlements.isPro {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(entitlements.status == .subscribed(plan: .monthly, until: nil, isTrial: false))
    }

    @Test func restoreBringsProBack() async {
        let store = FakeProStore()
        let entitlements = Entitlements(store: store)
        #expect(await entitlements.restore() == false)
        store.restored = .lifetime
        #expect(await entitlements.restore())
        #expect(entitlements.status == .lifetime)
    }

    @Test func thePlansAreAskedForOnce() async {
        let store = FakeProStore()
        let entitlements = Entitlements(store: store)
        await entitlements.loadOffers()
        await entitlements.loadOffers()
        #expect(entitlements.offers.map(\.plan) == [.yearly, .monthly, .lifetime])
        #expect(entitlements.offer(for: .monthly)?.displayPrice == "$9.99")
        #expect(store.offerCalls == 1)
    }

    /// DEBUG builds and tests can be Pro, or Free, whatever was bought.
    @Test func anOverrideWinsOverThePurchase() async {
        let entitlements = Entitlements(store: FakeProStore(), override: true)
        #expect(entitlements.isPro)
        entitlements.override = false
        _ = await entitlements.purchase(.lifetime)
        #expect(!entitlements.isPro)
        entitlements.override = nil
        #expect(entitlements.isPro)
    }
}
