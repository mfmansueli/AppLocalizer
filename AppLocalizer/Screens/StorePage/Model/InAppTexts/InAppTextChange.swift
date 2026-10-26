//
//  InAppTextChange.swift
//  AppLocalizer
//

import Foundation

/// One pending in-app text change for Review & Push.
struct InAppTextChange: Identifiable, Hashable, Sendable {
    let locale: StoreLocale
    let column: InAppTextColumn
    let oldValue: String
    let newValue: String
    let source: ChangeSource
    /// Over the limit: listed, skipped by Push.
    let blockReason: ListingBlockReason?

    /// E.g. `de-DE.lumen.plus.annual.description`.
    var id: String { "\(locale.code).\(column.id)" }

    var isBlocked: Bool { blockReason != nil }

    /// "German · Annual · description".
    var title: String { "\(locale.name) · \(column.title)" }
}
