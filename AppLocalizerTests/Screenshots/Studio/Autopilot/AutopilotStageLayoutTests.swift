//
//  AutopilotStageLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The sizes the Autopilot sheet's stages lay out with: Pick's columns,
/// Capture's device frame and its thumbnails.
@MainActor
@Suite("Autopilot stage layout")
struct AutopilotStageLayoutTests {
    @Test(arguments: [
        (CGFloat(1000), 5, CGFloat(168)), // plenty of room: capped
        (600, 5, 107), // (600 − 4 × 16) ÷ 5, rounded down
        (300, 5, 104), // too narrow: the row scrolls
        (150, 0, 150), // no screens counts as one
        (900, 1, 168),
    ])
    func pickColumnsShareTheRow(rowWidth: CGFloat, screens: Int, width: CGFloat) {
        #expect(AutopilotPickStageView.columnWidth(for: rowWidth, screens: screens, spacing: 16) == width)
    }

    @Test func withoutACaptureTheFrameIsAPortraitPhone() {
        let size = AutopilotSimulatorFrame.frameSize(for: .iPhone, pixelSize: ScreenshotDisplayType.iPhone.portraitPixelSize)
        #expect(size.width == 166)
        #expect(abs(size.height - (CGFloat(152) * 2868 / 1320 + 14)) < 0.001)
    }

    @Test func aLandscapeIPadCaptureGetsAWideIPadFrame() {
        let size = AutopilotSimulatorFrame.frameSize(for: .iPad, pixelSize: PixelSize(width: 2752, height: 2064))
        #expect(size.width == 260)
        #expect(size.height == 198.5) // 246 × 2064 ÷ 2752 + the bezel
    }

    @Test(arguments: [
        (ScreenshotDisplayType.iPad, PixelSize(width: 2064, height: 2752)),
        (.iPhone, PixelSize(width: 2868, height: 1320)),
    ])
    func otherCapturesKeepThePhonesWidth(display: ScreenshotDisplayType, size: PixelSize) {
        #expect(AutopilotSimulatorFrame.frameSize(for: display, pixelSize: size).width == 166)
    }

    @Test func theWatchHasAThickBezelAndRoundCorners() {
        let shape = AutopilotSimulatorFrame.shape(for: .watch, pixelSize: ScreenshotDisplayType.watch.portraitPixelSize)
        #expect(shape.bezel > AutopilotSimulatorFrame.shape(for: .iPhone, pixelSize: ScreenshotDisplayType.iPhone.portraitPixelSize).bezel)
        let size = AutopilotSimulatorFrame.frameSize(for: .watch, pixelSize: PixelSize(width: 422, height: 514))
        #expect(size.width == 152) // 134 + 2 × 9
        #expect(abs(size.height - (CGFloat(134) * 514 / 422 + 18)) < 0.001)
    }

    @Test func appleVisionProFloatsInAWideRoom() {
        let size = AutopilotSimulatorFrame.frameSize(for: .visionPro, pixelSize: PixelSize(width: 2560, height: 1440))
        #expect(size == CGSize(width: 300, height: 156))
    }

    @Test(arguments: [
        (ScreenshotDisplayType.iPhone, PixelSize(width: 1320, height: 2868), CGFloat(44)),
        (.iPad, PixelSize(width: 2752, height: 2064), 88), // 128, capped
        (.visionPro, PixelSize(width: 2560, height: 1440), 88),
        (.watch, PixelSize(width: 422, height: 514), 39),
        (.iPhone, PixelSize(width: 0, height: 0), 44),
    ])
    func captureThumbnailsShareAHeight(display: ScreenshotDisplayType, size: PixelSize, width: CGFloat) {
        #expect(AutopilotCaptureStageView.thumbnailWidth(for: display, pixelSize: size) == width)
    }
}
