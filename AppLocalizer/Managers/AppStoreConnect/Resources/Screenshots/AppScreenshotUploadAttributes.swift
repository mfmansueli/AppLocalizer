//
//  AppScreenshotUploadAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appScreenshots` resource's attributes while it's being uploaded:
/// where to send the file's parts, and how far Apple got with it.
struct AppScreenshotUploadAttributes: Decodable, Sendable {
    var fileName: String?
    var sourceFileChecksum: String?
    /// Set on a reservation: one operation per part of the file.
    var uploadOperations: [ScreenshotUploadOperation]?
    var assetDeliveryState: ScreenshotDeliveryState?
}
