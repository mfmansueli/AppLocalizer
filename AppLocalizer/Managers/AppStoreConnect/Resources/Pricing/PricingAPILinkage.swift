//
//  PricingAPILinkage.swift
//  AppLocalizer
//

import Foundation

/// A relationship's `data`: one identifier for to-one relationships, a list
/// for to-many ones.
enum PricingAPILinkage: Decodable, Sendable {
    case one(PricingAPIIdentifier)
    case many([PricingAPIIdentifier])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([PricingAPIIdentifier].self) {
            self = .many(list)
        } else {
            self = try .one(container.decode(PricingAPIIdentifier.self))
        }
    }

    var identifiers: [PricingAPIIdentifier] {
        switch self {
        case let .one(identifier): [identifier]
        case let .many(identifiers): identifiers
        }
    }
}
