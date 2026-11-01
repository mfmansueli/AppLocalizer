//
//  ScreenshotsDocument+Ratings.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsDocument {
    /// The countries whose App Store rating the template's laurels and
    /// badges are checked against.
    func ratingCountries(in locales: [StoreLocale]) -> Set<String> {
        template?.ratingCountries(scope: scope, locales: locales) ?? []
    }
}
