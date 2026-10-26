//
//  PriceSchedule.swift
//  AppLocalizer
//

import Foundation

/// When one subscription's queued price changes take effect, and whether
/// existing subscribers keep what they pay today. It applies to every price
/// change of that subscription in the push, and it's written into each
/// change's `POST /v1/subscriptionPrices` (`startDate`,
/// `preserveCurrentPrice`), so the queue is its source of truth.
struct PriceSchedule: Hashable, Sendable {
    /// The start day as App Store Connect takes it ("2026-11-02"); nil
    /// means as soon as Apple processes the change.
    var startDay: String?
    /// Existing subscribers keep their price; only new ones get increases.
    var preservesCurrentPrice = true

    /// As soon as Apple processes it, existing subscribers keeping their price:
    /// what every change starts with.
    static let immediate = PriceSchedule()

    var isScheduled: Bool { startDay != nil }

    /// The start day as a date (midnight GMT), or nil when immediate.
    var startDate: Date? {
        startDay.flatMap { try? PriceIndexEdition.parseDay($0) }
    }

    /// The review group's line: "Prices change on Nov 2, 2026 · existing
    /// subscribers keep their price".
    var note: String {
        let start = startDate.map { String(localized: "Prices change on \(PricingText.date($0))") }
            ?? String(localized: "Prices change as soon as Apple processes them")
        guard preservesCurrentPrice else { return start }
        return start + " · " + String(localized: "existing subscribers keep their price")
    }

    /// The bottom bar's button: "Starts now" or "Starts Nov 2, 2026".
    var buttonTitle: String {
        startDate.map { String(localized: "Starts \(PricingText.date($0))") } ?? String(localized: "Starts now")
    }

    /// "2026-11-02" for a day picked in `calendar` (the Mac's own, since
    /// that's the day the person sees).
    static func day(of date: Date, in calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// The date `day` falls on in `calendar`, for the date picker.
    static func date(ofDay day: String, in calendar: Calendar = .current) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
