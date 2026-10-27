//
//  AIProviderAPI.swift
//  AppLocalizer
//

import Foundation

/// One vendor's HTTP API for a single translation: the request for a
/// prompt, and the text in its answer.
protocol AIProviderAPI: Sendable {
    func request(for prompt: AIProviderTranslationPrompt, apiKey: String) throws -> URLRequest
    /// The answer's text. Throws when the model declined or was cut off.
    func text(from data: Data) throws -> String
}
