//
//  SubscriptionGroupLocalizationAttributes.swift
//  AppLocalizer
//

import Foundation

/// A `subscriptionGroupLocalizations` resource: the group's display name in
/// one locale.
struct SubscriptionGroupLocalizationAttributes: Decodable, Sendable {
    var locale: String
    var name: String?
}
