//
//  ScreenshotThumbnailer.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import ImageIO

/// Small images of kept screenshots, decoded straight to the size shown
/// rather than at their full 1320 × 2868.
enum ScreenshotThumbnailer {
    static func thumbnail(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
