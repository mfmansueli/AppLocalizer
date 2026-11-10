//
//  AppStorePreviewModel+Facts.swift
//  AppLocalizer
//

import Foundation

// The page's texts as App Store Connect has them (for the Overview, which
// has no editor), and the facts around them from the overview summaries:
// age rating and category from App Information, purchases from Pricing.
extension AppStorePreviewModel {
    /// One language's texts as App Store Connect has them, with no
    /// suggestions on top.
    init(content: StorePageContent, locale: StoreLocale) {
        let texts = content.texts[locale] ?? [:]
        func text(_ field: ListingField) -> AppStorePreviewText {
            AppStorePreviewText(value: texts[field] ?? "")
        }
        self.init(
            locale: locale,
            name: text(.name),
            subtitle: text(.subtitle),
            promotionalText: text(.promotionalText),
            description: text(.description),
            whatsNew: text(.whatsNew),
            versionString: content.version.versionString
        )
    }

    /// Adds the age rating, the category and the purchases with their base
    /// prices, when the summaries have them.
    mutating func addFacts(appInformation: AppInformationSummary?, pricing: PricingSummary?) {
        ageRating = appInformation?.ageRating
        category = appInformation?.category
        purchases = pricing?.products.map { Purchase(id: $0.id, name: $0.name, price: $0.basePrice) } ?? []
    }
}
