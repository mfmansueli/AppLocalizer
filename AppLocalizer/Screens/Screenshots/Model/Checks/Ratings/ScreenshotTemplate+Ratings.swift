//
//  ScreenshotTemplate+Ratings.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotTemplate {
    /// Whether any slot draws a laurel or a badge, whose numbers must
    /// match the App Store.
    var showsRatings: Bool {
        slots.indices.contains { slot in
            resolved(forSlot: slot).decorations?.contains(where: \.isRating) == true
        }
    }

    /// One country per localized locale (Germany for de-DE, Japan for
    /// ja), or none when no slot shows a rating.
    func ratingCountries(scope: LocaleScope, locales: [StoreLocale]) -> Set<String> {
        guard showsRatings else { return [] }
        return Set(locales.filter { scope.contains($0.code) && !scope.isPinned($0.code) }.map { $0.regionCode.uppercased() })
    }
}
