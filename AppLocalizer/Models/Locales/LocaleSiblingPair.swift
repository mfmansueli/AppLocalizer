//
//  LocaleSiblingPair.swift
//  AppLocalizer
//

import Foundation

/// Two locales of the same language, for "Copy from a sibling locale":
/// `source`'s text fills what `target` is missing.
struct LocaleSiblingPair: Identifiable, Hashable, Sendable {
    let source: StoreLocale
    let target: StoreLocale

    var id: String { "\(source.code)→\(target.code)" }

    /// The Fill menu item, e.g. "English (U.S.) → English (U.K.)".
    var title: String { "\(source.name) → \(target.name)" }
}
