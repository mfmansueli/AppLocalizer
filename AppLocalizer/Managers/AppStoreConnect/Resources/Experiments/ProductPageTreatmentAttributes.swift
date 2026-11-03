//
//  ProductPageTreatmentAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appStoreVersionExperimentTreatments` resource's attributes.
struct ProductPageTreatmentAttributes: Decodable, Sendable {
    var name: String?

    private enum CodingKeys: String, CodingKey {
        case name
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decodeIfPresent(String.self, forKey: .name)
    }
}
