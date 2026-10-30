//
//  DebugKeyAssistantService.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Canned answers for DEBUG scenes and UI tests, never the vendor: a key
/// shorter than 24 characters or containing "wrong" is rejected (401),
/// the test request writes Lumen's subtitle, and Generate Suggestions…
/// answers with What's New and promotional text from the commits.
struct DebugKeyAssistantService: KeyAssistantService {
    var delay: Duration = .milliseconds(700)

    func modelIDs(vendor: AIProviderVendor, apiKey: String) async throws -> [String] {
        try await Task.sleep(for: delay)
        if apiKey.count < 24 || apiKey.localizedCaseInsensitiveContains("wrong") {
            throw KeyAssistantKeyError.rejected(vendor, statusCode: 401)
        }
        switch vendor {
        case .anthropic: return ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"]
        case .openAI: return ["gpt-5.5", "gpt-5.5-mini"]
        case .gemini: return ["gemini-2.5-pro", "gemini-2.5-flash"]
        }
    }

    func complete(_ completion: AIProviderCompletion, vendor _: AIProviderVendor, apiKey _: String) async throws -> KeyAssistantAnswer {
        try await Task.sleep(for: delay)
        guard completion.wantsJSON else {
            return KeyAssistantAnswer(text: "“Private diary, mood & prompts”", tokens: 400, duration: .milliseconds(2100))
        }
        return KeyAssistantAnswer(text: Self.suggestions, tokens: 9400, duration: .milliseconds(6800))
    }

    static let suggestions = """
    {"suggestions": [
      {"locale": "en-US", "field": "whatsNew", \
    "value": "• Weekly reflections: a calm summary of your week, every Sunday\\n• Mood tags on every entry\\n• Search is twice as fast", \
    "reason": "From the 23 commits since v1.3 and CHANGELOG.md’s 1.4 section."},
      {"locale": "en-US", "field": "promotionalText", \
    "value": "New in 1.4: weekly reflections turn your entries into a gentle Sunday summary.", \
    "reason": "Leads with 1.4’s main feature, which reviews ask for most."},
      {"locale": "de-DE", "field": "whatsNew", \
    "value": "• Wochenrückblick: jeden Sonntag eine ruhige Zusammenfassung\\n• Stimmungs-Tags für jeden Eintrag\\n• Doppelt so schnelle Suche", \
    "reason": "German What’s New from the same commits."}
    ]}
    """
}
#endif
