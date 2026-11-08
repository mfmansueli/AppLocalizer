//
//  ScreenshotChecker+Reviews.swift
//  AppLocalizer
//

import Foundation

// A Reviews slot shows only real 5-star App Store reviews: three from the
// language's own storefront, or the primary language's filling in, which
// the person looks at before push. Without any, there's nothing to show.
extension ScreenshotChecker {
    static func reviewsCheck(_ reviews: LayoutReviews, layout: ScreenshotLayout, primaryLocaleName: String) -> RenderCheck {
        let locale = StoreLocaleCatalog.locale(code: layout.locale)
        let country = locale.map { Locale.current.localizedString(forRegionCode: $0.regionCode) ?? $0.regionCode } ?? layout.locale
        let shown = reviews.own + reviews.borrowed
        if shown == 0 {
            guard reviews.isChecked else {
                return RenderCheck(
                    kind: .reviews, status: .warning,
                    text: String(localized: "Reviews not read yet: couldn’t read the App Store reviews in \(country), so this slot shows its capture"),
                    shortReason: String(localized: "Reviews unread")
                )
            }
            // The slot shows its capture instead: nothing is empty, but it
            // isn't the Reviews screen the template has.
            return RenderCheck(
                kind: .reviews, status: .warning,
                text: String(localized: "No 5-star App Store reviews in \(country) yet, so this slot shows its capture instead of reviews"),
                shortReason: String(localized: "No reviews")
            )
        }
        if reviews.borrowed > 0 {
            return RenderCheck(
                kind: .reviews, status: .warning,
                text: String(localized: "\(reviews.borrowed) of \(shown) reviews are \(primaryLocaleName) reviews: \(country) has fewer than three yet"),
                shortReason: String(localized: "Borrowed reviews")
            )
        }
        return RenderCheck(kind: .reviews, status: .passed, text: String(localized: "\(shown) real App Store reviews from \(country)"))
    }
}
