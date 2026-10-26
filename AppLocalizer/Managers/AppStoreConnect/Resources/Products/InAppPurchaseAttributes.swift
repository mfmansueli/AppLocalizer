//
//  InAppPurchaseAttributes.swift
//  AppLocalizer
//

import Foundation

/// The fields AppLocalizer reads from an `inAppPurchases` (v2) resource.
struct InAppPurchaseAttributes: Decodable, Sendable {
    var name: String
    var productId: String
    var inAppPurchaseType: String?
    var state: String?
}
