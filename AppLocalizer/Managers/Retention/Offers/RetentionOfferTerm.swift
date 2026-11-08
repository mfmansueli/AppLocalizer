//
//  RetentionOfferTerm.swift
//  AppLocalizer
//

import Foundation

/// How many months an offer lasts, as App Store Connect stores it: a
/// `duration` and a `periodCount`. Free and pay-up-front offers are one
/// period of the whole length; pay as you go repeats the subscription's
/// own billing period, so three months on a monthly subscription is three
/// one-month periods.
struct RetentionOfferTerm: Hashable, Sendable {
    var duration: RetentionOfferDuration
    var periodCount: Int

    /// The term for `months` of `mode` on a subscription billed every
    /// `period`; nil when it can't be expressed (pay as you go for a part of
    /// a billing period, or a length App Store Connect has no duration for).
    static func make(mode: RetentionOfferMode, months: Int, period: SubscriptionPeriod?) -> RetentionOfferTerm? {
        guard months > 0 else { return nil }
        switch mode {
        case .free, .payUpFront:
            return RetentionOfferDuration(months: months).map { RetentionOfferTerm(duration: $0, periodCount: 1) }
        case .payAsYouGo:
            guard let period, let billing = RetentionOfferDuration(period: period), let length = billing.months,
                  months % length == 0
            else { return nil }
            return RetentionOfferTerm(duration: billing, periodCount: months / length)
        }
    }

    /// The whole offer in months, or nil for days and weeks.
    var totalMonths: Int? {
        duration.months.map { $0 * periodCount }
    }
}
