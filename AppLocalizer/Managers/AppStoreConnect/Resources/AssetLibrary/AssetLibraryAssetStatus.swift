//
//  AssetLibraryAssetStatus.swift
//  AppLocalizer
//

import Foundation

/// Where an uploaded asset is in App Store Connect: `AWAITING_UPLOAD`,
/// `UPLOAD_COMPLETE` while Apple processes it, then `COMPLETE` or
/// `PREPARE_FOR_SUBMISSION` once it can be placed, through review to
/// `APPROVED`. `FAILED` carries Apple's reasons in `details`.
struct AssetLibraryAssetStatus: Hashable, Sendable {
    var state: String?
    var details: [AssetLibraryStateDetail] = []

    /// States in which processing is over and the asset can be placed.
    static let readyStates: Set<String> = [
        "COMPLETE", "PREPARE_FOR_SUBMISSION", "READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW", "ACCEPTED", "APPROVED",
    ]

    /// States an asset never leaves for a usable one.
    static let failedStates: Set<String> = ["FAILED", "REJECTED", "ARCHIVED"]

    var isReady: Bool { state.map(Self.readyStates.contains) ?? false }
    var isFailed: Bool { state.map(Self.failedStates.contains) ?? false }

    /// Apple's reasons on one line, e.g. "IMAGE_INCORRECT_DIMENSIONS — The
    /// image is 3000 × 1286; IMAGE_ALPHA_NOT_ALLOWED"; nil when it gave none.
    var detailText: String? {
        let lines = details.compactMap(\.text)
        return lines.isEmpty ? nil : lines.joined(separator: "; ")
    }
}
