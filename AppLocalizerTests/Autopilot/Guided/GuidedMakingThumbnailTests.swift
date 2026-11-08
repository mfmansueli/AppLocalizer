//
//  GuidedMakingThumbnailTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Making it's capture thumbnails share a height: a landscape capture is
/// wider than a phone's, up to a cap.
@MainActor
@Suite("Guided making · capture thumbnails")
struct GuidedMakingThumbnailTests {
    @Test(arguments: [
        (ScreenshotDisplayType.iPhone, PixelSize(width: 1320, height: 2868), CGFloat(44)),
        (.iPad, PixelSize(width: 2752, height: 2064), 88), // 128, capped
        (.visionPro, PixelSize(width: 2560, height: 1440), 88),
        (.watch, PixelSize(width: 422, height: 514), 39),
        (.iPhone, PixelSize(width: 0, height: 0), 44),
    ])
    func captureThumbnailsShareAHeight(display: ScreenshotDisplayType, size: PixelSize, width: CGFloat) {
        #expect(GuidedMakingStepView.thumbnailWidth(for: display, pixelSize: size) == width)
    }
}
