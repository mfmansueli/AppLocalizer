//
//  ScreenshotChecker+Rating.swift
//  AppLocalizer
//

import Foundation

// Ratings must be true (README "Templates"): a laurel or badge may not show
// more than the app's App Store rating in the locale's country, and none
// at all before the app has one there, since Apple rejects misleading
// screenshots.
extension ScreenshotChecker {
    /// Nil when the render shows no rating. The highest number shown is
    /// compared with the store's, both at one decimal as the App Store
    /// shows them.
    static func ratingCheck(_ layout: ScreenshotLayout, ratings: StoreRatings) -> RenderCheck? {
        guard let shown = layout.decorations.compactMap(\.ratingValue).max(),
              let locale = StoreLocaleCatalog.locale(code: layout.locale)
        else { return nil }
        let country = Locale.current.localizedString(forRegionCode: locale.regionCode) ?? locale.regionCode
        // As the laurel and the App Store write them: 4.8, whatever the
        // Mac's number format.
        let shownText = String(format: "%.1f", shown)
        switch ratings.status(for: locale) {
        case let .rated(average):
            let store = (average * 10).rounded() / 10
            let storeText = String(format: "%.1f", store)
            if (shown * 10).rounded() > store * 10 {
                return RenderCheck(
                    kind: .rating, status: .failed,
                    text: String(localized: "Rating too high: \(shownText) shown, but the App Store shows \(storeText) in \(country)"),
                    shortReason: String(localized: "Rating too high")
                )
            }
            return RenderCheck(kind: .rating, status: .passed, text: String(localized: "Rating \(shownText) is true: the App Store shows \(storeText) in \(country)"))
        case .unrated:
            return RenderCheck(
                kind: .rating, status: .failed,
                text: String(localized: "Rating not earned: the app has no App Store rating in \(country) yet"),
                shortReason: String(localized: "No rating")
            )
        case .unknown:
            return RenderCheck(
                kind: .rating, status: .warning,
                text: String(localized: "Rating not checked: couldn’t read the App Store rating in \(country)"),
                shortReason: String(localized: "Rating unchecked")
            )
        }
    }
}
