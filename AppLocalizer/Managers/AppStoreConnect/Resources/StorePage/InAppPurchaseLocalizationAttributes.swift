//
//  InAppPurchaseLocalizationAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `inAppPurchaseLocalizations` resource: an in-app purchase's display
/// name and description in one locale.
struct InAppPurchaseLocalizationAttributes: Decodable, Sendable {
    var locale: String
    var name: String?
    var description: String?
}
