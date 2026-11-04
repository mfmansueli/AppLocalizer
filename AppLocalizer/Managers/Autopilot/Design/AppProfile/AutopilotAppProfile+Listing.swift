//
//  AutopilotAppProfile+Listing.swift
//  AppLocalizer
//

import Foundation

extension AutopilotAppProfile {
    /// The profile from the app's listing as AppLocalizer has it (App Store
    /// Connect's texts with anything queued on top), for the plan's
    /// `locales`, primary first; languages the page doesn't have yet are
    /// left out.
    init(listing: StoreListing, locales: [String], categories: [String], palette: IconPalette?) {
        let primary = listing.primaryLocale
        func text(_ field: ListingField, _ locale: StoreLocale) -> String {
            listing.draft(field, in: locale).local.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let codes = [primary.code] + locales.filter { $0 != primary.code }
        let languages = codes.compactMap { code in listing.locales.first { $0.code == code } }.map { locale in
            Language(
                locale: locale.code, name: text(.name, locale), subtitle: text(.subtitle, locale),
                keywords: Self.keywords(text(.keywords, locale))
            )
        }
        let name = text(.name, primary)
        self.init(
            name: name.isEmpty ? listing.appName : name,
            subtitle: text(.subtitle, primary),
            categories: categories,
            promotionalText: text(.promotionalText, primary),
            description: Self.opening(of: text(.description, primary)),
            languages: languages,
            iconColors: palette.map { [$0.light, $0.dark] } ?? []
        )
    }
}
