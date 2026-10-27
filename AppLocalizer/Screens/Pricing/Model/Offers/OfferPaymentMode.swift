//
//  OfferPaymentMode.swift
//  AppLocalizer
//

import Foundation

/// How an offer is paid, as App Store Connect names it.
enum OfferPaymentMode: String, CaseIterable, Hashable, Sendable {
    /// Nothing to pay for the offer's duration.
    case freeTrial
    /// A discounted price each period, for a number of periods.
    case payAsYouGo
    /// One discounted payment for the whole duration.
    case payUpFront

    var title: String {
        switch self {
        case .freeTrial: String(localized: "Free trial")
        case .payAsYouGo: String(localized: "Pay as you go")
        case .payUpFront: String(localized: "Pay up front")
        }
    }
}
