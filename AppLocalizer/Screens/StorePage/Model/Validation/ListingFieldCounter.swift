//
//  ListingFieldCounter.swift
//  AppLocalizer
//

import Foundation

/// The live counter at a field's trailing edge: "15 / 30", "456 / 4,000",
/// or "114 / 100 bytes" for keywords. Over the limit, it turns into a red
/// pill and the change can't be pushed.
struct ListingFieldCounter: Hashable, Sendable {
    let count: Int
    let limit: ListingTextLimit

    init(_ text: String, limit: ListingTextLimit) {
        count = limit.count(text)
        self.limit = limit
    }

    var isOverLimit: Bool { count > limit.maximum }

    /// How far past the limit, or 0.
    var overBy: Int { max(0, count - limit.maximum) }

    var text: String {
        let current = count.formatted()
        let maximum = limit.maximum.formatted()
        switch limit.unit {
        case .characters: return "\(current) / \(maximum)"
        case .bytes: return String(localized: "\(current) / \(maximum) bytes")
        }
    }

    /// "15 of 30 characters", or "Over the limit, 31 of 30 characters".
    var accessibilityLabel: String {
        isOverLimit
            ? String(localized: "Over the limit, \(count) of \(limit.maximum) \(limit.unit.name)")
            : String(localized: "\(count) of \(limit.maximum) \(limit.unit.name)")
    }
}
