//
//  TranslationProvider+Captions.swift
//  AppLocalizer
//

import Foundation

/// The copy "Translate missing captions" shows for each provider.
extension TranslationProvider {
    /// What the provider does with a caption.
    var captionDetail: String {
        switch self {
        case .appleTranslation:
            String(localized: "Free and private. Translates the caption as written.")
        case .aiProvider:
            String(localized: "Can write shorter, natural captions. Uses the API key in Settings.")
        case .assistant:
            String(localized: "Claude Code or another paired assistant, on its own plan. Arrives as proposals.")
        }
    }

    /// "AI provider · Anthropic"; the other providers keep their title.
    func captionTitle(vendor: AIProviderVendor) -> String {
        title(vendor: vendor)
    }
}
