//
//  InAppTextProductKind.swift
//  AppLocalizer
//

import Foundation

/// Whether a product's texts are a subscription's or an in-app purchase's.
enum InAppTextProductKind: Hashable, Sendable {
    case subscription
    case inAppPurchase

    var nameField: InAppTextField {
        self == .subscription ? .subscriptionName : .purchaseName
    }

    var descriptionField: InAppTextField {
        self == .subscription ? .subscriptionDescription : .purchaseDescription
    }
}
