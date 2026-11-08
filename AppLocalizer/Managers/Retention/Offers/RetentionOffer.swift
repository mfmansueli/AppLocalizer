//
//  RetentionOffer.swift
//  AppLocalizer
//

import Foundation

/// A retention offer: a lower price (or free time) Apple can show someone
/// about to cancel, in place of the message's image. A new offer type
/// (offerType 5 in App Store Server API transactions); up to 10 per
/// subscription, and Apple picks who's eligible and shows the best one.
struct RetentionOffer: Identifiable, Hashable, Codable, Sendable {
    /// App Store Connect's ID, or `new.<offerId>` while it waits in Review
    /// & Push.
    var id: String
    var subscriptionID: String
    var referenceName: String
    /// `offerId`: letters, digits, `_` and `.`.
    var offerID: String
    var mode: RetentionOfferMode
    var duration: RetentionOfferDuration
    var periodCount: Int
    /// The price in the United States in US dollars: each period's for pay
    /// as you go, the whole offer's up front; nil when free or unknown.
    var usPrice: Decimal?
    /// `customerEligibilityPaidSubscriptionDurationInMonths`.
    var paidMonths = 1
    /// `customerEligibilityWaitBetweenOffersInMonths`.
    var waitMonths: Int?
    /// Linked to the subscription's retention message
    /// (`retentionMessageOffers`), so Apple can show it.
    var isShown = false
    /// New, waiting in Review & Push.
    var isQueued = false

    static let newPrefix = "new."

    var term: RetentionOfferTerm {
        RetentionOfferTerm(duration: duration, periodCount: periodCount)
    }

    /// "pay as you go, 50% off · $2.49 a month for 3 months, set by
    /// country" or "free for 1 month"; `basePrice` is the subscription's
    /// usual US price, for the percentage.
    func terms(basePrice: Decimal?, period: SubscriptionPeriod?) -> String {
        let length = term.totalMonths.map(RetentionOfferDuration.monthsTitle) ?? duration.title
        switch mode {
        case .free:
            return String(localized: "free for \(length)")
        case .payAsYouGo:
            let price = usPrice.map { CurrencyFormat.usd.format($0) } ?? "—"
            let per = period == .oneYear ? String(localized: "a year") : String(localized: "a month")
            var parts = [mode.phrase]
            if let percent = Self.percentOff(price: usPrice, base: basePrice) { parts[0] += String(localized: ", \(percent)% off") }
            parts.append(String(localized: "\(price) \(per) for \(length), set by country"))
            return parts.joined(separator: " · ")
        case .payUpFront:
            let price = usPrice.map { CurrencyFormat.usd.format($0) } ?? "—"
            return String(localized: "\(mode.phrase) · \(price) for \(length), set by country")
        }
    }

    /// Whole percent below `base`, or nil.
    static func percentOff(price: Decimal?, base: Decimal?) -> Int? {
        guard let price, let base, base > 0, price < base else { return nil }
        let fraction = NSDecimalNumber(decimal: (base - price) / base).doubleValue
        return Int((fraction * 100).rounded())
    }
}
