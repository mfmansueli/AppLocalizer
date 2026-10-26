//
//  ResultsEvaluator.swift
//  AppLocalizer
//

import Foundation

/// Before-and-after rules for the Results tab: 28-day windows either side of
/// a change, plain verdicts, and "too little data" under 10 starts.
enum ResultsEvaluator {
    static let windowDays = 28
    /// Fewer starts than this on both sides is too little data.
    static let minimumStarts = 10

    static func verdict(before: SalesWindow, after: SalesWindow) -> ResultVerdict {
        if before.starts < minimumStarts, after.starts < minimumStarts { return .tooLittleData }
        guard after.starts > before.starts else { return .worse }
        return after.proceeds >= before.proceeds ? .better : .moreStartsLessProceeds
    }

    /// Too early until 28 days have passed since the change (the change day
    /// is day 1), then ready.
    static func availability(changedOn date: Date, now: Date, calendar: Calendar = .gmtGregorian) -> ResultsAvailability {
        let start = calendar.startOfDay(for: date)
        let elapsed = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        guard elapsed < windowDays else { return .ready }
        let arrivesOn = calendar.date(byAdding: .day, value: windowDays, to: start) ?? start
        return .tooEarly(day: max(elapsed, 0) + 1, arrivesOn: arrivesOn)
    }

    /// Totals over the territories with enough data.
    static func summarize(_ results: [PriceChangeResult]) -> ResultsSummary {
        let counted = results.filter(\.verdict.hasEnoughData)
        return ResultsSummary(
            territoryCount: results.count,
            countedCount: counted.count,
            betterCount: counted.count { $0.verdict == .better },
            worseCount: counted.count { $0.verdict == .worse },
            tooLittleDataCount: results.count - counted.count,
            startsBefore: counted.reduce(0) { $0 + $1.before.starts },
            startsAfter: counted.reduce(0) { $0 + $1.after.starts },
            proceedsBefore: counted.reduce(0) { $0 + $1.before.proceeds },
            proceedsAfter: counted.reduce(0) { $0 + $1.after.proceeds }
        )
    }

    /// Proceeds of `starts` at `price`, in US dollars: starts × price ÷ (1 +
    /// tax) × (1 − commission) ÷ the currency's rate.
    static func proceeds(
        starts: Int,
        price: Decimal,
        territory: Territory,
        commission: Commission,
        rates: ExchangeRates = .approximate
    ) -> Decimal {
        let local = commission.proceeds(customerPrice: price, taxRate: territory.taxRate) * Decimal(starts)
        return rates.dollars(local, currency: territory.currencyCode) ?? local
    }
}
