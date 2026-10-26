//
//  AppleListingTranslator.swift
//  AppLocalizer
//

import Foundation
import Translation

/// `ListingTranslator` backed by Apple's Translation framework, entirely on
/// this Mac. Languages have to be downloaded first (System Settings, or the
/// Translate sheet's "Download…", which asks through `.translationTask`).
struct AppleListingTranslator: ListingTranslator {
    func availability(from source: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        let status = await LanguageAvailability().status(from: source.language, to: target.language)
        switch status {
        case .installed: return .ready
        case .supported: return .needsDownload
        case .unsupported: return .unsupported
        @unknown default: return .unsupported
        }
    }

    func translate(_ text: String, field _: ListingField, from source: StoreLocale, to target: StoreLocale) async throws -> String {
        let session = TranslationSession(installedSource: source.language, target: target.language)
        return try await session.translate(text).targetText
    }
}
