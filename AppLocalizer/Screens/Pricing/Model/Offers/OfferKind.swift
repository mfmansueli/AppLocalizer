//
//  OfferKind.swift
//  AppLocalizer
//

import Foundation

/// The kinds of subscription offer App Store Connect has.
enum OfferKind: String, CaseIterable, Hashable, Sendable {
    case introductory
    case promotional
    case winBack
    case offerCode

    /// The offer list's group: "Introductory offers".
    var groupTitle: String {
        switch self {
        case .introductory: String(localized: "Introductory offers")
        case .promotional: String(localized: "Promotional offers")
        case .winBack: String(localized: "Win-back offers")
        case .offerCode: String(localized: "Offer codes")
        }
    }

    /// The editor's badge: "Introductory offer".
    var title: String {
        switch self {
        case .introductory: String(localized: "Introductory offer")
        case .promotional: String(localized: "Promotional offer")
        case .winBack: String(localized: "Win-back offer")
        case .offerCode: String(localized: "Offer code")
        }
    }
}
