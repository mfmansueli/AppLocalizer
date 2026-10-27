//
//  SubscriptionPeriod.swift
//  AppLocalizer
//

import Foundation

/// How long one billing period of a subscription lasts, with App Store
/// Connect's raw values.
enum SubscriptionPeriod: String, CaseIterable, Hashable, Sendable {
    case oneWeek = "ONE_WEEK"
    case oneMonth = "ONE_MONTH"
    case twoMonths = "TWO_MONTHS"
    case threeMonths = "THREE_MONTHS"
    case sixMonths = "SIX_MONTHS"
    case oneYear = "ONE_YEAR"

    var title: String {
        switch self {
        case .oneWeek: String(localized: "1 week")
        case .oneMonth: String(localized: "1 month")
        case .twoMonths: String(localized: "2 months")
        case .threeMonths: String(localized: "3 months")
        case .sixMonths: String(localized: "6 months")
        case .oneYear: String(localized: "1 year")
        }
    }

    /// A short name for menus, such as “Copy from Monthly”.
    var shortTitle: String {
        switch self {
        case .oneWeek: String(localized: "Weekly")
        case .oneMonth: String(localized: "Monthly")
        case .twoMonths: String(localized: "2-Month")
        case .threeMonths: String(localized: "Quarterly")
        case .sixMonths: String(localized: "6-Month")
        case .oneYear: String(localized: "Annual")
        }
    }
}
