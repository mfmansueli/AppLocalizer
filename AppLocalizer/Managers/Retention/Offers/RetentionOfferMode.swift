//
//  RetentionOfferMode.swift
//  AppLocalizer
//

import Foundation

/// How a retention offer is paid, with App Store Connect's `offerMode`
/// values: free for a while, a lower price each period, or one lower price
/// up front for the whole time.
enum RetentionOfferMode: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case free = "FREE_TRIAL"
    case payAsYouGo = "PAY_AS_YOU_GO"
    case payUpFront = "PAY_UP_FRONT"

    var id: String { rawValue }

    /// The sheet's Type control: "Free", "Pay as you go", "Pay up front".
    var title: String {
        switch self {
        case .free: String(localized: "Free")
        case .payAsYouGo: String(localized: "Pay as you go")
        case .payUpFront: String(localized: "Pay up front")
        }
    }

    /// Lowercase, for summaries: "pay as you go".
    var phrase: String {
        switch self {
        case .free: String(localized: "free")
        case .payAsYouGo: String(localized: "pay as you go")
        case .payUpFront: String(localized: "pay up front")
        }
    }

    var hasPrice: Bool { self != .free }
}
