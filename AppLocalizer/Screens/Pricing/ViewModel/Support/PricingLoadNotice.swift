//
//  PricingLoadNotice.swift
//  AppLocalizer
//

import Foundation

/// Which workspace banner a failed pricing read deserves: offline, the
/// hourly limit, or Apple's error text.
enum PricingLoadNotice {
    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
    ]

    static func notice(for error: any Error, now: Date = .now, calendar: Calendar = .current) -> PushNotice {
        if let error = error as? URLError, offlineCodes.contains(error.code) { return .offline }
        if let error = error as? AppStoreConnectError, error == .rateLimited {
            let hour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
            return .rateLimited(resumeAt: hour.addingTimeInterval(3600))
        }
        return .apiError(error.localizedDescription)
    }
}
