//
//  FakeProStore.swift
//  AppLocalizerTests
//

import Foundation
import Synchronization
@testable import AppLocalizer

/// AppLocalizer Pro's store without the App Store: U.S. prices, and each
/// purchase ending the way the test says.
final class FakeProStore: ProStore, @unchecked Sendable {
    private let state = Mutex(State())

    private struct State {
        var offers = FakeProStore.usOffers
        var owned = ProStatus.free
        var outcome: ProPurchaseOutcome?
        var restored = ProStatus.free
        var purchases: [ProPlan] = []
        var offerCalls = 0
    }

    static let trialEnd = Date(timeIntervalSince1970: 1_794_873_600)

    static let usOffers = [
        ProOffer(plan: .yearly, displayPrice: "$59.99", price: 59.99, monthlyDisplayPrice: "$5.00", trialDays: 7),
        ProOffer(plan: .monthly, displayPrice: "$9.99", price: 9.99),
        ProOffer(plan: .lifetime, displayPrice: "$149.99", price: 149.99),
    ]

    var offersOnSale: [ProOffer] {
        get { state.withLock { $0.offers } }
        set { state.withLock { $0.offers = newValue } }
    }

    var owned: ProStatus {
        get { state.withLock { $0.owned } }
        set { state.withLock { $0.owned = newValue } }
    }

    /// How the next purchases end; nil buys the plan.
    var outcome: ProPurchaseOutcome? {
        get { state.withLock { $0.outcome } }
        set { state.withLock { $0.outcome = newValue } }
    }

    /// What Restore Purchases finds.
    var restored: ProStatus {
        get { state.withLock { $0.restored } }
        set { state.withLock { $0.restored = newValue } }
    }

    var purchases: [ProPlan] { state.withLock { $0.purchases } }
    var offerCalls: Int { state.withLock { $0.offerCalls } }

    func offers() async -> [ProOffer] {
        state.withLock {
            $0.offerCalls += 1
            return $0.offers
        }
    }

    func status() async -> ProStatus { owned }

    func purchase(_ plan: ProPlan) async -> ProPurchaseOutcome {
        state.withLock { state in
            state.purchases.append(plan)
            if let outcome = state.outcome { return outcome }
            let status: ProStatus = switch plan {
            case .lifetime: .lifetime
            case .yearly: .subscribed(plan: .yearly, until: Self.trialEnd, isTrial: true)
            case .monthly: .subscribed(plan: .monthly, until: Self.trialEnd, isTrial: false)
            }
            state.owned = status
            return .purchased(status)
        }
    }

    func restore() async -> ProStatus {
        state.withLock {
            $0.owned = $0.restored
            return $0.restored
        }
    }

    func statusUpdates() -> AsyncStream<ProStatus> {
        AsyncStream { $0.finish() }
    }
}
