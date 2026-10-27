//
//  PushItemStatus.swift
//  AppLocalizer
//

import Foundation

/// Where one change stands in a push: queued ○ → sending → done ✓, or
/// failed with Apple's code, or not sent.
enum PushItemStatus: Hashable, Sendable {
    case queued
    case sending
    case done
    /// Apple refused it; the text is its code and detail.
    case failed(String)
    /// App Store Connect has a different value now; it waits in review.
    case conflict
    /// Not sent: cancelled, rate limited, offline or discarded meanwhile.
    case notSent(String)

    var isFinished: Bool {
        switch self {
        case .queued, .sending: false
        case .done, .failed, .conflict, .notSent: true
        }
    }

    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }
}
