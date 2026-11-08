//
//  RetentionContent.swift
//  AppLocalizer
//

import Foundation

/// Everything Pricing → Retention reads for one app: its subscriptions, the
/// retention messages App Store Connect has, every subscription's retention
/// offers, and the languages messages are written in.
struct RetentionContent: Hashable, Sendable {
    var subscriptions: [RetentionSubscription]
    var messages: [RetentionMessage]
    var offers: [RetentionOffer]
    /// Source first.
    var languages: [StoreLocale]
    /// What the others are translated from, usually English (U.S.).
    var sourceLocale: StoreLocale

    static let empty = RetentionContent(subscriptions: [], messages: [], offers: [], languages: RetentionLanguages.standard, sourceLocale: .englishUS)

    func subscription(id: String) -> RetentionSubscription? {
        subscriptions.first { $0.id == id }
    }

    func offers(for subscriptionID: String) -> [RetentionOffer] {
        offers.filter { $0.subscriptionID == subscriptionID }
    }
}
