//
//  ProductPageTreatmentLocaleAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appStoreVersionExperimentTreatmentLocalizations` resource's
/// attributes.
struct ProductPageTreatmentLocaleAttributes: Decodable, Sendable {
    var locale: String?

    private enum CodingKeys: String, CodingKey {
        case locale
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = try? container.decodeIfPresent(String.self, forKey: .locale)
    }
}
