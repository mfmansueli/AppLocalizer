//
//  LiveScreenshotTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A live screenshot's image: its URL from App Store Connect's template,
/// and why there's none when its upload is unfinished, failed or still
/// processing.
@MainActor
@Suite("LiveScreenshot")
struct LiveScreenshotTests {
    private static let processed = LiveScreenshot(
        id: "s1", fileName: "one.png", checksum: "c1", pixelSize: PixelSize(width: 1320, height: 2868),
        imageURLTemplate: "https://example.invalid/s1/{w}x{h}bb.{f}", deliveryState: ScreenshotDeliveryState(state: "COMPLETE")
    )

    private static func withoutImage(_ state: String?) -> LiveScreenshot {
        LiveScreenshot(id: "s2", fileName: "two.png", deliveryState: state.map { ScreenshotDeliveryState(state: $0) })
    }

    @Test func aProcessedScreenshotHasItsImage() {
        #expect(Self.processed.missingImage == nil)
        #expect(Self.processed.imageURL(width: 660)?.absoluteString == "https://example.invalid/s1/660x1434bb.png")
    }

    @Test func oneStillProcessingHasNoImageYet() {
        #expect(Self.withoutImage("UPLOAD_COMPLETE").missingImage == .stillProcessing)
    }

    @Test func anUnfinishedOrFailedUploadHasNoImageAtAll() {
        #expect(Self.withoutImage("AWAITING_UPLOAD").missingImage == .noImage)
        #expect(Self.withoutImage("FAILED").missingImage == .noImage)
        #expect(Self.withoutImage(nil).missingImage == .noImage)
    }

    @Test func thePushDoesntDownloadAScreenshotWithNoImage() async {
        let transport = FakeHTTPTransport([])
        let services = LiveScreenshotPushServices(client: AppStoreConnectClient(credentials: TestKeys.credentials(), transport: transport))
        await #expect(throws: LiveScreenshotImageError.noImage) { try await services.liveImageData(Self.withoutImage("FAILED")) }
        await #expect(throws: LiveScreenshotImageError.stillProcessing) { try await services.liveImageData(Self.withoutImage("UPLOAD_COMPLETE")) }
        #expect(transport.requests.isEmpty)
    }
}
