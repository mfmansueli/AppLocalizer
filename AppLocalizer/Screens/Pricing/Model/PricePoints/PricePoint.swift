//
//  PricePoint.swift
//  AppLocalizer
//

import Foundation

/// One of Apple's fixed prices in a territory. A price is only ever one of
/// these, never a free-form amount.
struct PricePoint: Hashable, Sendable {
    /// What the customer pays, tax included, in the territory's currency.
    var customerPrice: Decimal
    /// What the developer receives after tax and Apple's commission.
    var proceeds: Decimal
    /// App Store Connect's price point ID, used when pushing. Nil for
    /// simulated points.
    var appStoreConnectID: String?

    init(customerPrice: Decimal, proceeds: Decimal, appStoreConnectID: String? = nil) {
        self.customerPrice = customerPrice
        self.proceeds = proceeds
        self.appStoreConnectID = appStoreConnectID
    }
}
