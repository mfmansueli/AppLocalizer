//
//  ScreenshotUploadHeader.swift
//  AppLocalizer
//

import Foundation

/// A header an upload operation asks for, e.g. `Content-Type: image/png`.
struct ScreenshotUploadHeader: Codable, Hashable, Sendable {
    var name: String
    var value: String
}
