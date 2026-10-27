//
//  AIProviderTranslationPrompt.swift
//  AppLocalizer
//

import Foundation

/// What the AI provider is asked for one field: the instructions (the
/// field's purpose and limit, the tone, the glossary placeholders) and the
/// text. Prompts stay in English whatever the app's language.
struct AIProviderTranslationPrompt: Hashable, Sendable {
    let system: String
    let user: String

    init(text: String, field: ListingField, source: StoreLocale, target: StoreLocale, tone: TranslationTone) {
        var lines = [
            "You translate the App Store product page of an iPhone, iPad or Mac app.",
            "Write natural, idiomatic \(target.name), as a native copywriter for the App Store would, not a word-for-word translation. Keep the tone \(tone.promptPhrase).",
            Self.guidance(for: field),
        ]
        if let limit = field.limit {
            let unit = limit.unit == .bytes ? "bytes in UTF-8" : "characters"
            lines.append("It must fit in \(limit.maximum) \(unit).")
        }
        lines.append("Placeholders such as ⟦0⟧ stand for brand names: keep each one exactly as written, where it fits in the sentence.")
        lines.append("Reply with the translated text only, without quotes, notes or explanations.")
        system = lines.joined(separator: " ")
        user = "Translate this \(Self.fieldName(field)) from \(source.name) into \(target.name):\n\n\(text)"
    }

    private static func guidance(for field: ListingField) -> String {
        switch field {
        case .name:
            "This is the app's name on the App Store."
        case .subtitle:
            "This is the subtitle under the app's name: one short line that says what the app is for."
        case .promotionalText:
            "This is short promotional text."
        case .description:
            "This is the app's description. Keep its paragraphs, line breaks and lists."
        case .keywords:
            "These are the search keywords: a comma-separated list with no spaces after the commas. "
                + "Choose the words people searching in this language would type, rather than translating each word, and don't repeat a word."
        case .whatsNew:
            "This is What's New for a release. Keep it friendly and short, and keep its line breaks and lists."
        case .privacyPolicyURL, .supportURL, .marketingURL:
            "This is a URL. Return it unchanged."
        }
    }

    private static func fieldName(_ field: ListingField) -> String {
        switch field {
        case .name: "app name"
        case .subtitle: "subtitle"
        case .promotionalText: "promotional text"
        case .description: "description"
        case .keywords: "keyword list"
        case .whatsNew: "What's New text"
        case .privacyPolicyURL, .supportURL, .marketingURL: "URL"
        }
    }
}
