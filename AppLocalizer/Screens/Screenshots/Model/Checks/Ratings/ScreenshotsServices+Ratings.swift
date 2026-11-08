//
//  ScreenshotsServices+Ratings.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsServices {
    /// Looks nothing up: every rating stays unknown, so checks only warn.
    func storeRatings(for _: StoreApp, countries _: Set<String>) async -> StoreRatings {
        .unchecked
    }

    /// Looks nothing up: a Reviews slot stays empty and its check warns.
    func storeReviews(for _: StoreApp, countries _: Set<String>) async -> StoreReviews {
        .none
    }
}
