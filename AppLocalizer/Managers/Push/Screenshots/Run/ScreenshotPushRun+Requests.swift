//
//  ScreenshotPushRun+Requests.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushRun {
    /// Sends an API request within the hourly budget: it waits out a used
    /// up hour first, and a 429 pauses and tries again.
    func send(_ request: PushRequest) async throws -> AppStoreConnectResponse {
        try await withinBudget { try await self.environment.transport.send(request) }
    }

    func fetch(_ path: String) async throws -> AppStoreConnectResponse {
        try await withinBudget { try await self.environment.transport.fetch(path) }
    }

    private func withinBudget(_ request: () async throws -> AppStoreConnectResponse) async throws -> AppStoreConnectResponse {
        while true {
            try await waitForBudget()
            do {
                let response = try await request()
                environment.rate.note(response.rateLimit)
                return response
            } catch AppStoreConnectError.rateLimited {
                environment.rate.note(AppStoreConnectRateLimit(limit: environment.rate.rateLimit.limit, remaining: 0))
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
    func status(for error: any Error, replaces: Bool) -> ScreenshotUploadStatus {
        switch error {
        case let failure as ScreenshotPushFailure:
            return .failed(failure.text(replaces: replaces))
        case is CancellationError:
            return .cancelled
        case let error as AppStoreConnectError:
            if error == .unauthorized || error == .invalidPrivateKey { stopReason = String(localized: "Not sent · the API key was refused") }
            return .failed(ScreenshotPushFailure.request(detail: Self.describe(error)).text(replaces: replaces))
        case let error as URLError where Self.offlineCodes.contains(error.code):
            stopReason = String(localized: "Not sent · offline")
            return .notSent(String(localized: "Not sent · offline"))
        default:
            return .failed(ScreenshotPushFailure.request(detail: Self.describe(error)).text(replaces: replaces))
        }
    }

    /// An error as one short sentence ending in a period.
    static func describe(_ error: any Error) -> String {
        let text = (error as? AppStoreConnectError)?.pushFailureText ?? error.localizedDescription
        return text.hasSuffix(".") ? text : text + "."
    }

    static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
    ]
}
