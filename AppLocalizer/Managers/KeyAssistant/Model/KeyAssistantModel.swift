//
//  KeyAssistantModel.swift
//  AppLocalizer
//

import Foundation

/// A model an API key can use for suggestions: Claude Sonnet 5.5, or the
/// one AppLocalizer recommends from an OpenAI or Gemini key's list.
struct KeyAssistantModel: Hashable, Codable, Identifiable, Sendable {
    /// The vendor's model ID, e.g. `claude-sonnet-5-5`.
    var id: String
    /// "Claude Sonnet 5.5", or the ID when the vendor has no friendlier one.
    var name: String
    /// The setup picker's row: "Claude Sonnet 5.5 · recommended", or
    /// "Recommended for your key".
    var pickerTitle: String
}
