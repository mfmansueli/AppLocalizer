//
//  ProductPageTreatmentLocalization.swift
//  AppLocalizer
//

import Foundation

/// A treatment's page in one language. Library assets are placed on it as
/// on a version localization, through the placement's
/// `appStoreVersionExperimentTreatmentLocalization` relationship.
struct ProductPageTreatmentLocalization: Hashable, Sendable, Identifiable {
    var id: String
    var locale: String?

    init(id: String, locale: String? = nil) {
        self.id = id
        self.locale = locale
    }

    init(_ resource: ScreenshotAPIResource<ProductPageTreatmentLocaleAttributes>) {
        self.init(id: resource.id, locale: resource.attributes?.locale)
    }
}
