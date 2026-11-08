//
//  RetentionOfferDuration.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect's `SubscriptionOfferDuration`: how long one period of
/// a retention offer lasts.
enum RetentionOfferDuration: String, CaseIterable, Hashable, Codable, Sendable {
    case threeDays = "THREE_DAYS"
    case oneWeek = "ONE_WEEK"
    case twoWeeks = "TWO_WEEKS"
    case oneMonth = "ONE_MONTH"
    case twoMonths = "TWO_MONTHS"
    case threeMonths = "THREE_MONTHS"
    case sixMonths = "SIX_MONTHS"
    case oneYear = "ONE_YEAR"

    /// Whole months, or nil for days and weeks.
    var months: Int? {
        switch self {
        case .threeDays, .oneWeek, .twoWeeks: nil
        case .oneMonth: 1
        case .twoMonths: 2
        case .threeMonths: 3
        case .sixMonths: 6
        case .oneYear: 12
        }
    }

    init?(months: Int) {
        guard let match = Self.allCases.first(where: { $0.months == months }) else { return nil }
        self = match
    }

    /// The duration of one billing period of `period`.
    init?(period: SubscriptionPeriod) {
        switch period {
        case .oneWeek: self = .oneWeek
        case .oneMonth: self = .oneMonth
        case .twoMonths: self = .twoMonths
        case .threeMonths: self = .threeMonths
        case .sixMonths: self = .sixMonths
        case .oneYear: self = .oneYear
        }
    }

    var title: String {
        switch self {
        case .threeDays: String(localized: "3 days")
        case .oneWeek: String(localized: "1 week")
        case .twoWeeks: String(localized: "2 weeks")
        case .oneMonth: String(localized: "1 month")
        case .twoMonths: String(localized: "2 months")
        case .threeMonths: String(localized: "3 months")
        case .sixMonths: String(localized: "6 months")
        case .oneYear: String(localized: "1 year")
        }
    }

    /// "1 month", "3 months": a whole number of months in words.
    static func monthsTitle(_ months: Int) -> String {
        if months == 12 { return String(localized: "1 year") }
        return months == 1 ? String(localized: "1 month") : String(localized: "\(months) months")
    }
}
