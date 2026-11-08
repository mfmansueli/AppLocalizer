//
//  RetentionLimits.swift
//  AppLocalizer
//

import Foundation

/// What App Store Connect allows for retention messages and offers (API
/// 4.6): a header of 66 characters and a message of 144 per language, a
/// reference name of 64, up to 10 messages per app and 10 retention offers
/// per subscription, and images 3840 pixels wide and 160 to 2160 tall.
enum RetentionLimits {
    static let headerLength = 66
    static let bodyLength = 144
    /// A message's reference name, which can't be changed once created.
    static let referenceNameLength = 64
    static let messagesPerApp = 10
    static let offersPerSubscription = 10
    static let imageWidth = 3840
    static let imageHeights = 160...2160
    /// `customerEligibilityPaidSubscriptionDurationInMonths`: how long someone
    /// must have paid before Apple offers them a retention offer.
    static let paidMonthsChoices = Array(1...24) + [36, 48, 60]
    /// `customerEligibilityWaitBetweenOffersInMonths`.
    static let waitMonths = 2...24

    /// How Apple counts a text: characters as people see them.
    static func length(of text: String) -> Int {
        text.count
    }
}
