//
//  DeviceScreensRenderingTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Apple Watch and Apple Vision Pro in the set: their own screens, how
/// each lays out (the watch capture as it is, a Vision Pro window under
/// its caption), their checks, and the sizes Autopilot accepts.
@MainActor
@Suite("Device screens · rendering")
struct DeviceScreensRenderingTests {
    private static let document = DebugEveryDevice.document
    private static var matrix: ScreenshotMatrix {
        ScreenshotsTestFixtures.matrix(document)
    }

    // MARK: - Document

    @Test func theDocumentNamesEachDevicesScreens() {
        let document = Self.document
        #expect(document.displays == [.iPhone, .iPad, .watch, .visionPro])
        #expect(document.slotCount(on: .watch) == 4)
        #expect(document.slotName(3, on: .watch) == "Watch face")
        #expect(document.captionSlot(3, on: .watch) == nil)
        #expect(document.slotCount(on: .visionPro) == 3)
        #expect(document.slotName(2, on: .visionPro) == "Search")
        #expect(document.captionSlot(2, on: .visionPro) == 2)
        #expect(document.slotCount(on: .iPhone) == 5)

        var cleared = document
        cleared.setScreens([], on: .watch)
        cleared.setScreens([], on: .visionPro)
        #expect(cleared.deviceScreens == nil)
        #expect(cleared.displays == [.iPhone, .iPad])
    }

    // MARK: - Matrix

    @Test func eachDeviceHasARowOfItsOwnSlots() throws {
        let matrix = Self.matrix
        #expect(matrix.displays == [.iPhone, .iPad, .watch, .visionPro])
        #expect(matrix.slotCount(on: .watch) == 4)
        #expect(matrix.row(locale: "de-DE", displayType: .watch).count == 4)
        #expect(matrix.row(locale: "de-DE", displayType: .visionPro).count == 3)

        let watch = try #require(matrix.cell(locale: "de-DE", displayType: .watch, slot: 2))
        #expect(watch.caption == nil, "The watch has no captions")
        #expect(watch.state.isPending)
        let vision = try #require(matrix.cell(locale: "de-DE", displayType: .visionPro, slot: 2))
        #expect(vision.caption?.headline == matrix.cell(locale: "de-DE", displayType: .iPhone, slot: 2)?.caption?.headline)
    }

    /// The sample's German "Search" caption is written to overflow; the
    /// Apple Vision Pro window under it fails with it, and nothing else does.
    @Test func onlyTheVisionProWindowUnderTheOverflowingCaptionFails() {
        let failed = Self.matrix.failedCells.filter(\.key.displayType.hasOwnScreens)
        #expect(failed.map { "\($0.key.locale)|\($0.key.displayType.mcpValue)|\($0.key.slot)" } == ["de-DE|vision|2"])
        #expect(Self.matrix.cell(locale: "de-DE", displayType: .iPhone, slot: 2)?.state == .failed(reason: "Overflow"))
    }

    // MARK: - Layout

    @Test func theWatchCaptureFillsItsCanvasWithoutACaption() throws {
        let layout = try #require(Self.matrix.cell(locale: "en-US", displayType: .watch, slot: 0)?.layout)
        #expect(layout.canvas.pixelSize == PixelSize(width: 422, height: 514))
        #expect(layout.lines.isEmpty)
        #expect(layout.screen == CGRect(x: 0, y: 0, width: layout.canvas.width, height: layout.canvas.height))
        #expect(layout.windowBar == nil)
    }

    @Test func aVisionProWindowFloatsUnderItsCentredCaption() throws {
        let layout = try #require(Self.matrix.cell(locale: "en-US", displayType: .visionPro, slot: 0)?.layout)
        #expect(layout.canvas.pixelSize == PixelSize(width: 3840, height: 2160))
        #expect(!layout.lines.isEmpty)
        #expect(abs(layout.captionBox.midX - layout.canvas.width / 2) < 1)
        #expect(layout.captionBox.minY < layout.canvas.height * 0.2)
        #expect(layout.screen.minY > layout.captionBox.maxY)
        #expect(layout.screen.width <= layout.canvas.width * 0.5 + 1)
        #expect(layout.screen.width > layout.canvas.width * 0.3, "Smaller only to make room for the caption")
        #expect(abs(layout.screen.height / layout.screen.width - 0.75) < 0.01, "The window keeps the capture's shape")
        #expect(layout.screenRim > 0)
        let bar = try #require(layout.windowBar)
        #expect(bar.minY > layout.screen.maxY)
        #expect(abs(bar.midX - layout.screen.midX) < 1)
    }

    @Test(arguments: [(PixelSize(width: 4000, height: 1000), 0.5625), (PixelSize(width: 1000, height: 3000), 1.25)])
    func aWindowsShapeIsKeptWithinReason(capture: PixelSize, aspect: Double) throws {
        let template = try #require(Self.document.template)
        let layout = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts).layout(
            template, slot: 0, locale: .englishUS, displayType: .visionPro,
            caption: ScreenshotCaption(headline: "Write a little every day"), captureSize: capture
        )
        #expect(abs(layout.screen.height / layout.screen.width - aspect) < 0.01)
    }

    // MARK: - Capture sizes

    @Test(arguments: [PixelSize(width: 422, height: 514), PixelSize(width: 410, height: 502)])
    func appleWatchTakesUltraAndSeries(size: PixelSize) throws {
        try AutopilotCenter.checkSize(size, for: .watch)
    }

    @Test func otherSizesAreRefusedWithWhatEachDeviceTakes() {
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 1320, height: 2868), for: .watch) }
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 800, height: 500), for: .visionPro) }
        #expect(throws: AutopilotError.self) { try AutopilotCenter.checkSize(PixelSize(width: 422, height: 514), for: .iPhone) }
    }

    @Test func aVisionProWindowCanBeAnySizeFromSixHundredUp() throws {
        try AutopilotCenter.checkSize(PixelSize(width: 2752, height: 2064), for: .visionPro)
        try AutopilotCenter.checkSize(PixelSize(width: 600, height: 900), for: .visionPro)
    }
}
#endif
