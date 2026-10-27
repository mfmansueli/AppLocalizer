//
//  DebugCaptionTranslator.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// DEBUG scenes' translator for captions: answers with the design's sample
/// captions for the English text it's given, a little slowly, and German's
/// shorter versions where the design has one. It never reaches Apple.
struct DebugCaptionTranslator: ListingTranslator {
    /// How long each caption takes.
    var delay: Duration = .milliseconds(70)
    /// The caption the batch stops at and never finishes: the progress
    /// banner's scene.
    var holdsAt: LocaleSlot?
    /// Languages that act as not downloaded yet.
    var notDownloaded: Set<String> = []

    func availability(from _: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        notDownloaded.contains(target.code) ? .needsDownload : .ready
    }

    func translate(_ text: String, field _: ListingField, from _: StoreLocale, to target: StoreLocale) async throws -> String {
        guard let position = Self.position(of: text) else { throw TranslationError.noSample(target) }
        let slot = position.slot
        let isSubhead = position.isSubhead
        if LocaleSlot(locale: target.code, slot: slot) == holdsAt {
            try await Task.sleep(for: .seconds(24 * 60 * 60))
        }
        try await Task.sleep(for: delay)
        if !isSubhead, let short = ScreenshotsSampleData.shorterCaptions[target.code]?[slot] { return short }
        guard let texts = ScreenshotsSampleData.captionTexts[target.code], texts.indices.contains(slot) else {
            throw TranslationError.noSample(target)
        }
        let parts = texts[slot].split(separator: "|", maxSplits: 1).map(String.init)
        return isSubhead ? (parts.count > 1 ? parts[1] : parts[0]) : parts[0]
    }

    /// The slot and part of an English sample caption.
    private static func position(of text: String) -> (slot: Int, isSubhead: Bool)? {
        let english = ScreenshotsSampleData.captionTexts[ScreenshotsSampleData.primary] ?? []
        for (slot, entry) in english.enumerated() {
            let parts = entry.split(separator: "|", maxSplits: 1).map(String.init)
            if parts[0] == text { return (slot, false) }
            if parts.count > 1, parts[1] == text { return (slot, true) }
        }
        return nil
    }

    /// The sample data has no caption for the locale.
    enum TranslationError: LocalizedError {
        case noSample(StoreLocale)

        var errorDescription: String? {
            switch self {
            case let .noSample(locale): String(localized: "The sample data has no \(locale.name) caption for this text.")
            }
        }
    }
}
#endif
