//
//  AIProviderKeyChecker.swift
//  AppLocalizer
//

import Foundation

/// Checks an AI provider key: Settings → Translation does it when a key is
/// saved, when the vendor changes and when the tab opens.
/// `LiveAIProviderKeyChecker` asks the vendor; DEBUG scenes and tests use
/// canned ones.
protocol AIProviderKeyChecker: Sendable {
    /// Throws `AIProviderError.unauthorized` (401 or 403), another
    /// `AIProviderError` or a `URLError` when the key can't be used or
    /// checked.
    func check(_ apiKey: String, for vendor: AIProviderVendor) async throws -> AIProviderKeyCheck
}
