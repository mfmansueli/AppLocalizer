//
//  DebugListingTranslator.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// A `ListingTranslator` for DEBUG scenes: the prototype's translations
/// after a short pause. It never runs Apple Translation, so scenes look the
/// same on every Mac.
struct DebugListingTranslator: ListingTranslator {
    /// How long each field takes.
    var delay: Duration = .milliseconds(60)
    /// The field the batch stops at and never finishes: the progress
    /// banner's scene.
    var holdsAt: ListingFieldKey?
    /// Languages that act as not downloaded yet.
    var notDownloaded: Set<StoreLocale> = []

    func availability(from _: StoreLocale, to target: StoreLocale) async -> TranslationAvailability {
        notDownloaded.contains(target) ? .needsDownload : .ready
    }

    func translate(_: String, field: ListingField, from _: StoreLocale, to target: StoreLocale) async throws -> String {
        if ListingFieldKey(target, field) == holdsAt {
            try await Task.sleep(for: .seconds(24 * 60 * 60))
        }
        try await Task.sleep(for: delay)
        guard let translation = StorePageSampleData.machineTranslations[target]?[field] else {
            throw TranslationError.noSample(target)
        }
        return translation
    }

    /// The sample has no translation for this field.
    enum TranslationError: LocalizedError {
        case noSample(StoreLocale)

        var errorDescription: String? {
            switch self {
            case let .noSample(locale): String(localized: "The sample data has no \(locale.name) translation for this field.")
            }
        }
    }
}
#endif
