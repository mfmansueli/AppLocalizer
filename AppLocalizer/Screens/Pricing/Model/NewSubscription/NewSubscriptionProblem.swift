//
//  NewSubscriptionProblem.swift
//  AppLocalizer
//

import Foundation

/// Why a new subscription can't be created as it is: Create Subscription
/// shows it under the field, and `propose_subscription` refuses with it.
enum NewSubscriptionProblem: Hashable, Sendable {
    case missing(NewSubscriptionField)
    case tooLong(NewSubscriptionField, count: Int)
    /// Letters, digits, `.` and `_` only.
    case invalidProductID
    /// The app has it, or another new subscription waiting in Review & Push.
    case productIDTaken(String)
    /// A new group named like one the app has.
    case groupExists(String)
    case invalidPrice

    var field: NewSubscriptionField {
        switch self {
        case let .missing(field), let .tooLong(field, _): field
        case .invalidProductID, .productIDTaken: .productID
        case .groupExists: .groupReferenceName
        case .invalidPrice: .price
        }
    }

    var message: String {
        switch self {
        case let .missing(field):
            String(localized: "\(field.title) is missing.")
        case let .tooLong(field, count):
            String(localized: "\(field.title) is \(count) characters; the limit is \(field.limit ?? count).")
        case .invalidProductID:
            String(localized: "A product ID can only have letters, digits, periods and underscores.")
        case let .productIDTaken(id):
            String(localized: "“\(id)” is already used. Product IDs can’t be used twice, even after a product is deleted.")
        case let .groupExists(name):
            String(localized: "The app already has a group named “\(name)”. Choose it instead of a new one.")
        case .invalidPrice:
            String(localized: "Enter a price in US dollars, above zero and with up to two decimals.")
        }
    }
}
