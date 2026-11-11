//
//  ProStore.swift
//  AppLocalizer
//

import Foundation

/// Where AppLocalizer Pro is sold and checked: the App Store through
/// StoreKit (`StoreKitProStore`), or a fake in tests and DEBUG scenes.
protocol ProStore: Sendable {
    /// The plans on sale, with this person's prices. Empty when the App
    /// Store can't be reached.
    func offers() async -> [ProOffer]
    /// What the person owns now.
    func status() async -> ProStatus
    func purchase(_ plan: ProPlan) async -> ProPurchaseOutcome
    /// Restore Purchases: asks the App Store again, then what they own.
    func restore() async -> ProStatus
    /// A status each time a purchase, renewal, refund or expiry arrives.
    func statusUpdates() -> AsyncStream<ProStatus>
}
