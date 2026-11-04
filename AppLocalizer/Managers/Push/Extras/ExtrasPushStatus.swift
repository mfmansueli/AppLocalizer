//
//  ExtrasPushStatus.swift
//  AppLocalizer
//

import Foundation

/// Where one extra is in its push.
enum ExtrasPushStatus: Hashable, Sendable {
    case waiting
    /// Its turn: AppLocalizer finds which groups it goes in (and, for an
    /// App Preview, that there's room) before uploading.
    case preparing
    /// Share of the file sent, 0…1.
    case uploading(Double)
    /// Uploaded; Apple is processing the file.
    case processing
    /// Processed; it's being placed on the page.
    case placing
    case done(assetID: String, placementIDs: [String])
    /// Why it didn't go, as one sentence for the row.
    case failed(String)
    /// Cancel Remaining stopped it before it started.
    case cancelled

    /// "Waiting", "Getting ready", "Uploading 42%", "Processing",
    /// "Placing", "Done", "Failed", "Cancelled".
    var title: String {
        switch self {
        case .waiting: return String(localized: "Waiting")
        case .preparing: return String(localized: "Getting ready")
        case let .uploading(fraction):
            let percent = Int((min(1, max(0, fraction)) * 100).rounded(.down))
            return String(localized: "Uploading \(percent)%")
        case .processing: return String(localized: "Processing")
        case .placing: return String(localized: "Placing")
        case .done: return String(localized: "Done")
        case .failed: return String(localized: "Failed")
        case .cancelled: return String(localized: "Cancelled")
        }
    }

    /// The red line under a failed row.
    var failureReason: String? {
        guard case let .failed(reason) = self else { return nil }
        return reason
    }

    var isDone: Bool {
        if case .done = self { return true }
        return false
    }

    var isFailure: Bool { failureReason != nil }

    var isFinished: Bool {
        switch self {
        case .done, .failed, .cancelled: true
        case .waiting, .preparing, .uploading, .processing, .placing: false
        }
    }
}
