//
//  SubscriptionLocalizationAttributes.swift
//  AppLocalizer
//

import Foundation

/// A `subscriptionLocalizations` resource: a subscription's display name and
/// description in one locale.
struct SubscriptionLocalizationAttributes: Decodable, Sendable {
    var locale: String
    var name: String?
    var description: String?
}
