//
//  PushRecord.swift
//  AppLocalizer
//

import Foundation

/// One finished push for one app, as Activity lists it: when, what, how many
/// succeeded or failed, and the changes themselves so "Restore Previous
/// Values" can queue the old values again.
struct PushRecord: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var date: Date
    var appID: StoreApp.ID
    var appName: String
    /// e.g. "Store Page · 24 texts in 8 locales".
    var title: String
    /// The changes that reached App Store Connect.
    var pushed: [PendingChange]
    /// Changes Apple rejected, with its error text, keyed by change id.
    var failures: [PendingChange.ID: String] = [:]
    /// Whether this push changed prices, so Results applies.
    var changedPrices: Bool { pushed.contains { $0.section == .subscriptionPricing } }

    var succeededCount: Int { pushed.count }
    var failedCount: Int { failures.count }
}
