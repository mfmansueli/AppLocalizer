//
//  DebugProStore.swift
//  AppLocalizer
//

#if DEBUG
import Foundation
import Synchronization

/// DEBUG only (`-AppLocalizerPro free`): AppLocalizer Pro's store without
/// the App Store, with the U.S. prices, so the paywall can be walked
/// through, bought and restored in DEBUG scenes and UI tests. Nothing is
/// charged, and nothing is kept after the app quits.
final class DebugProStore: ProStore, @unchecked Sendable {
    private let owned = Mutex(ProStatus.free)

    static let offers = [
        ProOffer(plan: .yearly, displayPrice: "$59.99", price: 59.99, monthlyDisplayPrice: "$5.00", trialDays: 7),
        ProOffer(plan: .monthly, displayPrice: "$9.99", price: 9.99),
        ProOffer(plan: .lifetime, displayPrice: "$149.99", price: 149.99),
    ]

    func offers() async -> [ProOffer] { Self.offers }

    func status() async -> ProStatus { owned.withLock { $0 } }

    func purchase(_ plan: ProPlan) async -> ProPurchaseOutcome {
        // The App Store's sheet takes a moment.
        try? await Task.sleep(for: .milliseconds(600))
        let status: ProStatus = switch plan {
        case .lifetime: .lifetime
        case .yearly: .subscribed(plan: .yearly, until: Date.now.addingTimeInterval(7 * 86400), isTrial: true)
        case .monthly: .subscribed(plan: .monthly, until: Date.now.addingTimeInterval(30 * 86400), isTrial: false)
        }
        owned.withLock { $0 = status }
        return .purchased(status)
    }

    func restore() async -> ProStatus { await status() }

    func statusUpdates() -> AsyncStream<ProStatus> {
        AsyncStream { $0.finish() }
    }
}
#endif
