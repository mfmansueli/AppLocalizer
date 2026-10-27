//
//  RequestRateTracker.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Counts App Store Connect requests against the hourly quota for every
/// kind of push: Apple's own count when a response reported it, otherwise
/// what this Mac sent in the last hour. Review & Push's rate meter and a
/// screenshot push's budget both read it.
@MainActor
@Observable
final class RequestRateTracker {
    private var reported: AppStoreConnectRateLimit?
    private var sentDates: [Date] = []
    @ObservationIgnored private let now: () -> Date

    init(now: @escaping () -> Date = { .now }, reported: AppStoreConnectRateLimit? = nil) {
        self.now = now
        self.reported = reported
    }

    var rateLimit: AppStoreConnectRateLimit {
        if let reported { return reported }
        let hourAgo = now().addingTimeInterval(-3600)
        let used = sentDates.count { $0 > hourAgo }
        let limit = AppStoreConnectRateLimit.defaultHourlyLimit
        return AppStoreConnectRateLimit(limit: limit, remaining: max(0, limit - used))
    }

    /// Notes one request, with the quota its response reported, if any.
    func note(_ rateLimit: AppStoreConnectRateLimit?) {
        let date = now()
        sentDates.append(date)
        sentDates.removeAll { $0 < date.addingTimeInterval(-3600) }
        if let rateLimit { reported = rateLimit }
    }

    /// A new hour began after a pause: what Apple reported before no
    /// longer holds.
    func startNewHour() {
        reported = nil
        sentDates.removeAll()
    }

    /// The start of the next hour, when a used-up quota is back.
    func nextHour() -> Date {
        let date = now()
        let start = Calendar.current.dateInterval(of: .hour, for: date)?.start ?? date
        return start.addingTimeInterval(3600)
    }
}
