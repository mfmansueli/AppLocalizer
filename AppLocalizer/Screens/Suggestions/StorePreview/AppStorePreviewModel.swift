//
//  AppStorePreviewModel.swift
//  AppLocalizer
//

import Foundation

/// What the App Store page preview shows for one language: the page's texts,
/// with suggestions laid on top when Suggested is picked, and the facts the
/// App Store shows around them.
struct AppStorePreviewModel: Equatable, Sendable {
    /// A subscription or purchase, with its price.
    struct Purchase: Identifiable, Equatable, Sendable {
        var id: String
        var name: String
        var price: String?
    }

    var locale: StoreLocale
    var name = AppStorePreviewText()
    var subtitle = AppStorePreviewText()
    var promotionalText = AppStorePreviewText()
    var description = AppStorePreviewText()
    var whatsNew = AppStorePreviewText()
    var versionString = ""
    var ratings = StoreRatings.unchecked
    var ageRating: String?
    var category: String?
    var purchases: [Purchase] = []

    var words: AppStoreWords { AppStoreWords.words(for: locale.code) }

    /// The storefront's average, "—" until there's one.
    var ratingText: String {
        guard case let .rated(average) = ratings.status(for: locale) else { return "—" }
        return average.formatted(.number.precision(.fractionLength(1)))
    }

    /// "220 Ratings", or the App Store's "No Ratings".
    var ratingCountText: String {
        guard case .rated = ratings.status(for: locale), let count = ratings.count(inCountry: locale.regionCode) else {
            return words.noRatings
        }
        return words.ratingsText(count)
    }

    /// The description's opening, as far as "more".
    static func clipped(_ text: String, to length: Int) -> String {
        guard text.count > length else { return text }
        return String(text.prefix(length)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }
}
