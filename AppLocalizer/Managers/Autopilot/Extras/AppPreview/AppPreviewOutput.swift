//
//  AppPreviewOutput.swift
//  AppLocalizer
//

import Foundation

/// The App Preview file AppLocalizer wrote.
struct AppPreviewOutput: Hashable, Sendable {
    var url: URL
    var seconds: Double
    var pixelSize: PixelSize
    var byteCount: Int64
}
