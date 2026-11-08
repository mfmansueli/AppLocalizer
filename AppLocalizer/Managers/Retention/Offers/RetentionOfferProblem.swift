//
//  RetentionOfferProblem.swift
//  AppLocalizer
//

import Foundation

/// Why a new retention offer can't be added, in the sheet and for
/// `propose_retention_offer`.
enum RetentionOfferProblem: Hashable, Sendable {
    case tooManyOffers(subscription: String)
    case nameTooLong
    case invalidPrice
    case priceNotLower(usual: String)
    case termUnavailable
    case invalidPaidMonths
    case invalidWaitMonths
    case offerIDTaken(String)

    var message: String {
        switch self {
        case let .tooManyOffers(subscription):
            String(localized: "\(subscription) already has \(RetentionLimits.offersPerSubscription) retention offers, Apple’s limit.")
        case .nameTooLong:
            String(localized: "The name is longer than \(RetentionLimits.referenceNameLength) characters.")
        case .invalidPrice:
            String(localized: "Enter the price in the United States in US dollars, e.g. 2.49.")
        case let .priceNotLower(usual):
            String(localized: "An offer’s price should be lower than the usual \(usual).")
        case .termUnavailable:
            String(localized: "Pay as you go repeats the subscription’s billing period; choose a whole number of periods.")
        case .invalidPaidMonths:
            String(localized: "Paid months before someone is eligible must be 1 to 24, 36, 48 or 60.")
        case .invalidWaitMonths:
            String(localized: "The wait between offers must be 2 to 24 months.")
        case let .offerIDTaken(offerID):
            String(localized: "The subscription already has an offer with the ID \(offerID).")
        }
    }
}
