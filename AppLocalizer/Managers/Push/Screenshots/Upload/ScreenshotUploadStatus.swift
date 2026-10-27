//
//  ScreenshotUploadStatus.swift
//  AppLocalizer
//

import Foundation

/// Where one image stands in a screenshot push: queued → (keeping a copy
/// of the live one →) reserving → uploading n% → committing → done, Apple
/// processing it; or failed with the reason, or never sent.
enum ScreenshotUploadStatus: Hashable, Sendable {
    case queued
    /// Downloading the live screenshot it replaces, to keep on this Mac.
    case keepingCopy
    case reserving
    /// The share of the file's parts sent, 0–1.
    case uploading(Double)
    case committing
    case done
    case failed(String)
    /// Cancel Remaining stopped it before it started.
    case cancelled
    /// The push stopped before it: offline, or the API key was refused.
    case notSent(String)

    var isFinished: Bool {
        switch self {
        case .done, .failed, .cancelled, .notSent: true
        case .queued, .keepingCopy, .reserving, .uploading, .committing: false
        }
    }

    var isActive: Bool {
        switch self {
        case .keepingCopy, .reserving, .uploading, .committing: true
        case .queued, .done, .failed, .cancelled, .notSent: false
        }
    }

    var isFailure: Bool {
        if case .failed = self { return true }
        return false
    }

    /// The upload's progress when the bar shows.
    var uploadFraction: Double? {
        if case let .uploading(fraction) = self { return fraction }
        return nil
    }

    /// The step column: "Uploading 64%", "Done · Apple is processing".
    var stepTitle: String {
        switch self {
        case .queued: String(localized: "Queued")
        case .keepingCopy: String(localized: "Keeping a copy…")
        case .reserving: String(localized: "Reserving…")
        case let .uploading(fraction): String(localized: "Uploading \(Int((fraction * 100).rounded()))%")
        case .committing: String(localized: "Committing…")
        case .done: String(localized: "Done · Apple is processing")
        case .failed: String(localized: "Failed")
        case .cancelled: String(localized: "Cancelled")
        case let .notSent(reason): reason
        }
    }

    /// The red line under a failed row.
    var failureText: String? {
        if case let .failed(text) = self { return text }
        return nil
    }
}
