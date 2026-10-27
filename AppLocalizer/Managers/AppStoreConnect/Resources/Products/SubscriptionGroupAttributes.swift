//
//  SubscriptionGroupAttributes.swift
//  AppLocalizer
//

import Foundation

/// The fields AppLocalizer reads from a `subscriptionGroups` resource.
struct SubscriptionGroupAttributes: Decodable, Sendable {
    var referenceName: String
}
