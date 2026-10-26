//
//  ScreenshotAPIResource.swift
//  AppLocalizer
//

import Foundation

/// A JSON:API resource from the screenshot endpoints: a set, a
/// screenshot, a preview set or a preview. Relationships use the same
/// linkage shape as every other App Store Connect resource.
struct ScreenshotAPIResource<Attributes: Decodable & Sendable>: Decodable, Sendable {
    var type: String
    var id: String
    var attributes: Attributes?
    var relationships: [String: PricingAPIRelationship]?

    /// The resources a to-many relationship links to, in order.
    func related(_ name: String) -> [PricingAPIIdentifier] {
        relationships?[name]?.data?.identifiers ?? []
    }
}
