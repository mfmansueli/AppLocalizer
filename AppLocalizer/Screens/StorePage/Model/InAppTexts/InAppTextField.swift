//
//  InAppTextField.swift
//  AppLocalizer
//

import Foundation

/// A localized text of a subscription group, subscription or in-app
/// purchase, shown on the purchase sheet and in Settings → Subscriptions.
///
/// The group name limit follows the design (30); App Store Connect's help
/// doesn't state one, so check it against the API's validation. A
/// subscription's description takes 55: Apple's help states 45 only for
/// in-app purchases, and Alba's 47–54-character subscription descriptions
/// are live in App Store Connect.
enum InAppTextField: String, CaseIterable, Hashable, Sendable {
    case subscriptionGroupName
    case subscriptionName
    case subscriptionDescription
    case purchaseName
    case purchaseDescription

    var limit: ListingTextLimit {
        switch self {
        case .subscriptionGroupName, .subscriptionName, .purchaseName: ListingTextLimit(30)
        case .subscriptionDescription: ListingTextLimit(55)
        case .purchaseDescription: ListingTextLimit(45)
        }
    }

    var title: String {
        switch self {
        case .subscriptionGroupName: String(localized: "Group name")
        case .subscriptionName, .purchaseName: String(localized: "Display name")
        case .subscriptionDescription, .purchaseDescription: String(localized: "Description")
        }
    }

    var isDescription: Bool {
        self == .subscriptionDescription || self == .purchaseDescription
    }

    /// The column title's second half, as in "Monthly · name".
    var columnSuffix: String {
        isDescription ? String(localized: "description") : String(localized: "name")
    }
}
