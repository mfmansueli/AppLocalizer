//
//  PricingAPIIdentifier.swift
//  AppLocalizer
//

import Foundation

/// A JSON:API resource identifier (`{"type": "territories", "id": "BRA"}`),
/// in responses and in the create requests pricing sends.
struct PricingAPIIdentifier: Codable, Hashable, Sendable {
    var type: String
    var id: String
}
