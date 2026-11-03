//
//  ExtrasPushRun+Requests.swift
//  AppLocalizer
//

import Foundation

extension ExtrasPushRun {
    /// Makes one API call within the hourly budget: it waits out a used up
    /// hour first, and a 429 pauses and tries again, a few times at most.
    func call<Result>(_ operation: () async throws -> Result) async throws -> Result {
        var refusals = 0
        while true {
            try await waitForBudget()
            do {
                let result = try await operation()
                environment.rate.note(nil)
                return result
            } catch AppStoreConnectError.rateLimited {
                environment.rate.note(AppStoreConnectRateLimit(limit: environment.rate.rateLimit.limit, remaining: 0))
                refusals += 1
                if refusals > environment.rateLimitRetries { throw AppStoreConnectError.rateLimited }
            } catch {
                environment.rate.note(nil)
                throw error
            }
        }
    }

    /// Pauses until the next hour while no requests are left. Cancel
    /// Remaining ends the wait.
    private func waitForBudget() async throws {
        while environment.rate.rateLimit.remaining <= 0 {
            let resume = pausedUntil ?? environment.rate.nextHour()
            pausedUntil = resume
            while environment.now() < resume {
                if isCancelling { throw CancellationError() }
                try await environment.sleep(.seconds(1))
            }
            if environment.rate.rateLimit.remaining <= 0 { environment.rate.startNewHour() }
            pausedUntil = nil
        }
    }

    /// The row status for an error. Offline and a refused key stop the
    /// rest of the push.
    func status(for error: any Error) -> ExtrasPushStatus {
        switch error {
        case let failure as ExtrasPushFailure:
            return .failed(failure.text)
        case is CancellationError:
            return .cancelled
        case let error as AppStoreConnectError:
            if error == .unauthorized || error == .invalidPrivateKey { stopReason = String(localized: "Not sent · the API key was refused") }
            return .failed(Self.describe(error))
        case let error as URLError where Self.offlineCodes.contains(error.code):
            let reason = String(localized: "Not sent · offline")
            stopReason = reason
            return .failed(reason)
        default:
            return .failed(Self.describe(error))
        }
    }

    /// An error as one short sentence ending in a period, with Apple's
    /// code and detail when it sent them.
    static func describe(_ error: any Error) -> String {
        let text = (error as? AppStoreConnectError)?.pushFailureText ?? error.localizedDescription
        return text.hasSuffix(".") ? text : text + "."
    }

    static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
    ]
}
