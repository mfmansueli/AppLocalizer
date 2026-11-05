//
//  NewSubscriptionField.swift
//  AppLocalizer
//

import Foundation

/// A field of Create Subscription, with App Store Connect's limit.
enum NewSubscriptionField: String, CaseIterable, Hashable, Sendable {
    case groupReferenceName
    case groupDisplayName
    case referenceName
    case productID
    case displayName
    case description
    case price
    case reviewNote

    var title: String {
        switch self {
        case .groupReferenceName: String(localized: "Group reference name")
        case .groupDisplayName: String(localized: "Group display name")
        case .referenceName: String(localized: "Reference name")
        case .productID: String(localized: "Product ID")
        case .displayName: String(localized: "Display name")
        case .description: String(localized: "Description")
        case .price: String(localized: "Price")
        case .reviewNote: String(localized: "Review notes")
        }
    }

    /// The display texts use In-App Texts' limits; reference names and
    /// product IDs App Store Connect's.
    var limit: Int? {
        switch self {
        case .groupReferenceName, .referenceName: 64
        case .productID: 100
        case .groupDisplayName: InAppTextField.subscriptionGroupName.limit.maximum
        case .displayName: InAppTextField.subscriptionName.limit.maximum
        case .description: InAppTextField.subscriptionDescription.limit.maximum
        case .reviewNote: 4000
        case .price: nil
        }
    }
}
