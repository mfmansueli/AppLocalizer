//
//  StorePageErrorReporter.swift
//  AppLocalizer
//

import Foundation

/// Turns a failed Store Page load into the message the section shows, and
/// tells the workspace banner about the connection, the rate limit or
/// Apple's error text.
enum StorePageErrorReporter {
    @MainActor
    static func report(_ error: any Error, to push: PushController?, now: Date = .now) -> String {
        if let error = error as? AppStoreConnectError {
            switch error {
            case .rateLimited: push?.report(.rateLimited(resumeAt: nextHour(after: now)))
            case .notFound: break
            default: push?.report(.apiError(error.pushFailureText))
            }
            return error.errorDescription ?? error.localizedDescription
        }
        if let error = error as? URLError, offlineCodes.contains(error.code) {
            push?.report(.offline)
        }
        return error.localizedDescription
    }

    static func nextHour(after date: Date) -> Date {
        let start = Calendar.current.dateInterval(of: .hour, for: date)?.start ?? date
        return start.addingTimeInterval(3600)
    }

    private static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .timedOut, .dnsLookupFailed,
    ]
}
