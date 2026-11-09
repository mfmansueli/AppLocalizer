//
//  ScreenshotDeliveryState.swift
//  AppLocalizer
//

import Foundation

/// `assetDeliveryState`: `AWAITING_UPLOAD`, `UPLOAD_COMPLETE`, `COMPLETE`
/// or `FAILED`, with Apple's errors when processing failed.
struct ScreenshotDeliveryState: Codable, Hashable, Sendable {
    var state: String
    var errors: [ScreenshotDeliveryMessage]?

    var isFailed: Bool { state == "FAILED" }
    /// Apple finished processing it.
    var isComplete: Bool { state == "COMPLETE" }

    /// The first error's code, e.g. `IMAGE_TOOL_FAILURE`.
    var errorCode: String? { errors?.first?.code }
}
