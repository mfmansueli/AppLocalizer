//
//  PricingAPIDocument.swift
//  AppLocalizer
//

import Foundation

/// A JSON:API list response with its `included` resources, the shape every
/// pricing endpoint answers with. `AppStoreConnectPage` drops `included` and
/// relationships, which pricing needs to tie a price to its territory and point.
struct PricingAPIDocument<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var data: [PricingAPIResource<Attributes>]
    var included: [PricingAPIIncluded]?
    var links: AppStoreConnectPageLinks?

    init(data: [PricingAPIResource<Attributes>], included: [PricingAPIIncluded]? = nil, links: AppStoreConnectPageLinks? = nil) {
        self.data = data
        self.included = included
        self.links = links
    }

    /// Included resources by type and ID, for following relationships.
    func includedByKey() -> [PricingAPIIdentifier: PricingAPIIncluded] {
        Dictionary((included ?? []).map { (PricingAPIIdentifier(type: $0.type, id: $0.id), $0) }, uniquingKeysWith: { first, _ in first })
    }
}
