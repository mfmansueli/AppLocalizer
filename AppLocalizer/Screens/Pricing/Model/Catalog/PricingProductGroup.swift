//
//  PricingProductGroup.swift
//  AppLocalizer
//

import Foundation

/// A subscription group, or the app's in-app purchases, as one section of
/// the browser.
struct PricingProductGroup: Identifiable, Hashable, Sendable {
    var id: String
    var name: String
    var isInAppPurchases: Bool
    var products: [PricingProduct]

    /// The browser's section header: “Lumen Plus · subscription group”.
    var title: String {
        isInAppPurchases ? String(localized: "In-App Purchases") : String(localized: "\(name) · subscription group")
    }
}
