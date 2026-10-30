//
//  AIProviderAPI.swift
//  AppLocalizer
//

import Foundation

/// One vendor's HTTP API: the request for a completion and the text in its
/// answer, the request that checks a key, and the models a key can use.
protocol AIProviderAPI: Sendable {
    /// The model translations use.
    var defaultModel: String { get }
    func request(for completion: AIProviderCompletion, apiKey: String) throws -> URLRequest
    /// `GET` the model translations use: it needs a working key that can
    /// reach that model, and it costs no tokens.
    func checkRequest(apiKey: String) -> URLRequest
    /// `GET` the models the key can use; it costs no tokens either.
    func modelsRequest(apiKey: String) -> URLRequest
    /// The model IDs in the models answer.
    func modelIDs(from data: Data) throws -> [String]
    /// The answer's text. Throws when the model declined or was cut off.
    func text(from data: Data) throws -> String
    /// Tokens in and out, as the answer counts them.
    func tokenCount(from data: Data) -> Int?
}

extension AIProviderAPI {
    /// A field's translation, on the default model at low effort.
    func request(for prompt: AIProviderTranslationPrompt, apiKey: String) throws -> URLRequest {
        try request(
            for: AIProviderCompletion(system: prompt.system, user: prompt.user, model: defaultModel, maxTokens: 16000, effort: "low"),
            apiKey: apiKey
        )
    }
}
