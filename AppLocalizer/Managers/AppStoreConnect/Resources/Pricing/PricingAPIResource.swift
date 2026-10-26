//
//  PricingAPIResource.swift
//  AppLocalizer
//

import Foundation

/// One JSON:API resource with typed attributes and its relationships.
struct PricingAPIResource<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var type: String
    var id: String
    var attributes: Attributes
    var relationships: [String: PricingAPIRelationship]?

    /// The single resource a to-one relationship points at, such as a price's territory.
    func related(_ name: String) -> PricingAPIIdentifier? {
        relationships?[name]?.data?.identifiers.first
    }

    /// Every resource a to-many relationship points at, such as a group's subscriptions.
    func relatedAll(_ name: String) -> [PricingAPIIdentifier] {
        relationships?[name]?.data?.identifiers ?? []
    }
}
