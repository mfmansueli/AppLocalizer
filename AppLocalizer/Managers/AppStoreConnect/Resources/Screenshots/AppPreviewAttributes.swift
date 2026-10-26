//
//  AppPreviewAttributes.swift
//  AppLocalizer
//

import Foundation

/// An `appPreviews` resource's attributes. App Store Connect doesn't say
/// how long a preview is.
struct AppPreviewAttributes: Decodable, Sendable {
    var fileName: String?
    /// The poster frame, e.g. "00:00:05:00".
    var previewFrameTimeCode: String?
    var mimeType: String?
}
