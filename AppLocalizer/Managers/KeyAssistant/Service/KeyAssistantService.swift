//
//  KeyAssistantService.swift
//  AppLocalizer
//

import Foundation

/// Talks to the provider behind an API key: the models the key can use,
/// and one completion. `LiveKeyAssistantService` asks the vendor; DEBUG
/// scenes and tests answer from canned data.
protocol KeyAssistantService: Sendable {
    /// Throws `KeyAssistantKeyError.rejected` for a key the vendor refuses,
    /// another `AIProviderError` or a `URLError` when it can't be checked.
    func modelIDs(vendor: AIProviderVendor, apiKey: String) async throws -> [String]
    func complete(_ completion: AIProviderCompletion, vendor: AIProviderVendor, apiKey: String) async throws -> KeyAssistantAnswer
}
