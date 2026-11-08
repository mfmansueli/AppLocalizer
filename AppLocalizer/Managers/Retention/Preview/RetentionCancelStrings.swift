//
//  RetentionCancelStrings.swift
//  AppLocalizer
//

import Foundation

/// Apple's own words on its Confirm Cancellation screen in one language,
/// for the preview around the message: the title, when the service ends,
/// "From the developer", the buttons, and an offer's line. The system
/// shows the real ones; these are close enough to judge the message by.
/// Placeholders: `{date}`, `{dur}`, `{pct}`, `{price}`, `{offer}`, `{per}`.
struct RetentionCancelStrings: Hashable, Sendable {
    var title: String
    var end: String
    var from: String
    var cancel: String
    var keep: String
    var accept: String
    var oneMonth = "1 month"
    var months = "{n} months"
    var perMonth = "/month"
    var perYear = "/year"
    var discount = "{dur} at {pct}% off, then {price}{per}"
    var free = "{dur} free, then {price}{per}"
    var upFront = "{dur} for {offer}, then {price}{per}"

    static let english = RetentionCancelStrings(
        title: "Confirm Cancellation",
        end: "If you cancel this subscription, your service will end on {date}.",
        from: "FROM THE DEVELOPER",
        cancel: "Cancel Subscription",
        keep: "Keep Subscription",
        accept: "Accept Offer"
    )

    /// The strings for a locale code: the exact one, then its language's,
    /// then English.
    static func strings(for code: String) -> RetentionCancelStrings {
        let language = String(code.split(separator: "-").first ?? "")
        return RetentionCancelCatalog.table[code] ?? RetentionCancelCatalog.table[language] ?? english
    }

    /// Whether the language reads right to left (Arabic, Hebrew, …).
    static func isRightToLeft(_ code: String) -> Bool {
        ["ar", "he", "fa", "ur"].contains(String(code.split(separator: "-").first ?? ""))
    }

    /// "If you cancel …, your service will end on December 14, 2026."
    func endText(date: Date, code: String) -> String {
        end.replacingOccurrences(of: "{date}", with: Self.format(date, code: code))
    }

    /// "3 months at 50% off, then $4.99/month".
    func offerLine(_ offer: RetentionOffer, basePrice: Decimal?, period: SubscriptionPeriod?) -> String {
        let total = offer.term.totalMonths ?? offer.duration.months ?? 1
        let duration = total == 1 ? oneMonth : months.replacingOccurrences(of: "{n}", with: "\(total)")
        let template: String = switch offer.mode {
        case .free: free
        case .payUpFront: upFront
        case .payAsYouGo: RetentionOffer.percentOff(price: offer.usPrice, base: basePrice) == nil ? upFront : discount
        }
        let percent = RetentionOffer.percentOff(price: offer.usPrice, base: basePrice).map(String.init) ?? ""
        return template
            .replacingOccurrences(of: "{dur}", with: duration)
            .replacingOccurrences(of: "{pct}", with: percent)
            .replacingOccurrences(of: "{offer}", with: offer.usPrice.map { CurrencyFormat.usd.format($0) } ?? "")
            .replacingOccurrences(of: "{price}", with: basePrice.map { CurrencyFormat.usd.format($0) } ?? "")
            .replacingOccurrences(of: "{per}", with: period == .oneYear ? perYear : perMonth)
    }

    /// The date as the language writes it, in the Gregorian calendar with
    /// Western digits, as Apple's screen shows it.
    static func format(_ date: Date, code: String) -> String {
        var style = Date.FormatStyle(date: .long, time: .omitted)
        style.locale = Locale(identifier: "\(code.replacingOccurrences(of: "-", with: "_"))@calendar=gregorian;numbers=latn")
        style.timeZone = TimeZone(identifier: "UTC") ?? .current
        return date.formatted(style)
    }
}
