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
        case .introductory: "Introductory offers"
        case .promotional: "Promotional offers"
        case .winBack: "Win-back offers"
        case .offerCode: "Offer codes"
        }
    }

    /// The editor's badge: "Introductory offer".
    var title: String {
        switch self {
        case .introductory: "Introductory offer"
        case .promotional: "Promotional offer"
        case .winBack: "Win-back offer"
        case .offerCode: "Offer code"
        }
    }
}
