//
//  AIProviderSetup.swift
//  AppLocalizer
//

import Foundation

/// Settings → Translation's AI provider as the Translate sheets see it: the
/// vendor, whether its key is saved, and a way to make its translator.
/// `makeTranslator` reads the key from the Keychain, so a batch calls it
/// once, when it starts.
struct AIProviderSetup: Sendable {
    let vendor: AIProviderVendor
    let hasKey: Bool
    let makeTranslator: @Sendable (TranslationTone) -> (any ListingTranslator)?

    /// The message the sheets show instead of starting, or nil when the key
    /// is saved.
    var setupMessage: String? {
        hasKey ? nil : TranslationProvider.aiProvider.setupMessage
    }

    /// No vendor key: what DEBUG scenes and tests start with.
    static let none = AIProviderSetup(vendor: .anthropic, hasKey: false) { _ in nil }
}
