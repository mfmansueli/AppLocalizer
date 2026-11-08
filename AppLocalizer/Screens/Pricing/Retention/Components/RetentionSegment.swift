//
//  RetentionSegment.swift
//  AppLocalizer
//

import Foundation

/// One choice of a `RetentionSegmentedControl`.
struct RetentionSegment<Value: Hashable>: Identifiable {
    var value: Value
    var title: String
    /// A small tag after the title, e.g. "New".
    var badge: String?
    /// A warning dot after the title, e.g. a language that runs too long.
    var hasWarning = false
    /// Said by VoiceOver after the title, e.g. "too long".
    var accessibilityNote: String?
    var identifier: String?

    var id: Value { value }
}
