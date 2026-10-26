//
//  PricingAPIRelationship.swift
//  AppLocalizer
//

import Foundation

/// A JSON:API relationship. Only its linkage (`data`) is read; it's absent
/// when the response didn't ask for it.
struct PricingAPIRelationship: Decodable, Sendable {
    var data: PricingAPILinkage?
}
