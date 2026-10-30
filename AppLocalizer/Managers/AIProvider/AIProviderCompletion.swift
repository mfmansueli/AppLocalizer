//
//  AIProviderCompletion.swift
//  AppLocalizer
//

import Foundation

/// One request to a model: the instructions, the text, which model and how
/// long the answer may be. Translations use the vendor's default model;
/// suggestions from an API key use the model chosen in setup.
struct AIProviderCompletion: Hashable, Sendable {
    var system: String
    var user: String
    var model: String
    var maxTokens: Int
    /// Anthropic's effort; nil leaves the model's default.
    var effort: String?
    /// Asks for a JSON answer, where the vendor can be told.
    var wantsJSON = false
}
