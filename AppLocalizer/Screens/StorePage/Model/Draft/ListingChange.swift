//
//  ListingChange.swift
//  AppLocalizer
//

import Foundation

/// One pending store-page change for Review & Push: old → new, with its
/// source tag, and why it's blocked when it can't be pushed.
struct ListingChange: Identifiable, Hashable, Sendable {
    let key: ListingFieldKey
    /// App Store Connect's value; empty means "Empty".
    let oldValue: String
    let newValue: String
    let source: ChangeSource
    let blockReason: ListingBlockReason?
    /// The assistant's version, when you both changed this field.
    let conflictingProposal: ListingAssistantProposal?

    var id: ListingFieldKey { key }
    var locale: StoreLocale { key.locale }
    var field: ListingField { key.field }

    /// Over the limit, an invalid URL or an unresolved conflict: listed,
    /// skipped by Push.
    var isBlocked: Bool { blockReason != nil }

    /// "German · Subtitle".
    var title: String { key.title }
}
