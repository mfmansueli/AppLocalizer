//
//  LocaleSlot.swift
//  AppLocalizer
//

import Foundation

/// One caption position: a locale and a slot, on every display type. The
/// captions table selects by it, translation items are keyed by it, and
/// the template editor focuses on one.
struct LocaleSlot: Hashable, Sendable, Identifiable, CustomStringConvertible {
    var locale: String
    /// 0-based; the UI shows `slot + 1`.
    var slot: Int

    var id: String { description }

    var description: String { "\(locale)|\(slot)" }
}
