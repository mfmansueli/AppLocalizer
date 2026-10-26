//
//  PricingAPIIncluded.swift
//  AppLocalizer
//

import Foundation

/// One resource from a response's `included` list. Its types differ
/// (subscriptions, price points, territories), so the attributes are the
/// union of the fields pricing reads, all optional.
struct PricingAPIIncluded: Decodable, Sendable {
    var type: String
    var id: String
    var attributes: Attributes?

    struct Attributes: Decodable, Sendable {
        var name: String?
        var productId: String?
        var state: String?
        var subscriptionPeriod: String?
        var customerPrice: String?
        var proceeds: String?
        var proceedsYear2: String?
        var currency: String?
    }
}
