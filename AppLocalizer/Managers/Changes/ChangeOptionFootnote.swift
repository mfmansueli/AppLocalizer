//
//  ChangeOptionFootnote.swift
//  AppLocalizer
//

import Foundation

/// The review footer's line about the changes whose `ChangeOption` is on:
/// "1 declaration publishes immediately when pushed" for one, and `other`
/// with `{count}` replaced for more. Both texts are localized by the section
/// that builds the change.
struct ChangeOptionFootnote: Hashable, Codable, Sendable {
    static let countPlaceholder = "{count}"

    /// The text for exactly one change.
    var one: String
    /// The text for any other count, with `{count}` where the number goes.
    var other: String

    func text(count: Int) -> String {
        count == 1 ? one : other.replacingOccurrences(of: Self.countPlaceholder, with: count.formatted())
    }
}
