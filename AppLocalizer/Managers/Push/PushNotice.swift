//
//  PushNotice.swift
//  AppLocalizer
//

import Foundation

/// What the workspace banner says after a push stopped or partly failed.
enum PushNotice: Hashable, Sendable {
    /// No connection: "Edits stay queued on this Mac".
    case offline
    /// The hourly quota ran out; pushing can resume at `resumeAt`.
    case rateLimited(resumeAt: Date)
    /// Apple returned an error that stopped the push, with its text.
    case apiError(String)
    /// Some changes failed: "2 of 26 failed".
    case partialFailure(failed: Int, total: Int)

    var kind: BannerKind {
        switch self {
        case .offline: .offline
        case .rateLimited: .rateLimited
        case .apiError: .apiError
        case .partialFailure: .partialFailure
        }
    }

    var title: String {
        switch self {
        case .offline:
            String(localized: "You're offline")
        case .rateLimited:
            String(localized: "App Store Connect's hourly limit was reached")
        case .apiError:
            String(localized: "App Store Connect returned an error")
        case let .partialFailure(failed, total):
            String(localized: "\(failed) of \(total) changes failed to push")
        }
    }

    var message: String {
        switch self {
        case .offline:
            String(localized: "Edits stay queued on this Mac. Push again when you're back online.")
        case let .rateLimited(resumeAt):
            String(localized: "Pushing resumes at \(resumeAt.formatted(date: .omitted, time: .shortened)); nothing is lost.")
        case let .apiError(text):
            text
        case .partialFailure:
            String(localized: "Failed changes stay in Review & Push with Apple's reason.")
        }
    }
}
