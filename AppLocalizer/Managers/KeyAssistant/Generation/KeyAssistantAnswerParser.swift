//
//  KeyAssistantAnswerParser.swift
//  AppLocalizer
//

import Foundation

/// Reads the suggestions out of a model's answer: `{"suggestions": […]}`
/// or a bare list, even inside a ```json fence or after a sentence.
enum KeyAssistantAnswerParser {
    static func items(from text: String, vendor: AIProviderVendor) throws -> [KeyAssistantSuggestionItem] {
        let decoder = JSONDecoder()
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}"), start < end,
           let wrapper = try? decoder.decode(Wrapper.self, from: Data(text[start...end].utf8))
        {
            return wrapper.suggestions
        }
        if let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]"), start < end,
           let items = try? decoder.decode([KeyAssistantSuggestionItem].self, from: Data(text[start...end].utf8))
        {
            return items
        }
        throw AIProviderError.unreadableResponse(vendor)
    }

    private struct Wrapper: Decodable {
        let suggestions: [KeyAssistantSuggestionItem]
    }
}
