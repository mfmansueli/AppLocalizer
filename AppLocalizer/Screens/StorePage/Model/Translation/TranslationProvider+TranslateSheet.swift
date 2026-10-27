//
//  TranslationProvider+TranslateSheet.swift
//  AppLocalizer
//

import Foundation

/// The copy "Translate Missing…" shows for each provider. The AI provider
/// needs its API key in Settings first, and the assistant a running server.
extension TranslationProvider {
    /// "AI provider · Anthropic"; the other providers keep their title.
    func title(vendor: AIProviderVendor) -> String {
        self == .aiProvider ? String(localized: "AI provider · \(vendor.title)") : title
    }

    /// The sheet's longer description of what the provider does differently.
    var detail: String {
        switch self {
        case .appleTranslation:
            String(localized: "Free and private. Translates the text as it is, with no keyword optimization.")
        case .aiProvider:
            String(localized: "App Store-optimized keywords and natural What’s New. Uses the API key in Settings.")
        case .assistant:
            String(localized: "Claude Code, Claude Desktop, Cursor or Codex, on your own plan. No API key here.")
        }
    }

    /// The progress banner's and suggestions' name: "Apple Translation".
    var shortTitle: String {
        switch self {
        case .appleTranslation: String(localized: "Apple Translation")
        case .aiProvider: String(localized: "your AI provider")
        case .assistant: String(localized: "your assistant")
        }
    }

    /// What's missing before it can translate, or nil when it's ready.
    var setupMessage: String? {
        switch self {
        case .appleTranslation:
            nil
        case .aiProvider:
            String(localized: "Add an AI provider and its API key in Settings → Translation first.")
        case .assistant:
            String(localized: "No assistant is connected yet. Turn on the local server in Settings → AI Assistants.")
        }
    }
}
