//
//  ProductPageTreatment.swift
//  AppLocalizer
//

import Foundation

/// One variant of a Product Page Optimization test, e.g. “Outcome”
/// against the current page's “Interface”.
struct ProductPageTreatment: Hashable, Sendable, Identifiable {
    var id: String
    var name: String?

    init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }

    init(_ resource: ScreenshotAPIResource<ProductPageTreatmentAttributes>) {
        self.init(id: resource.id, name: resource.attributes?.name)
    }
}
