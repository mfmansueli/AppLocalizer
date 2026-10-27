//
//  CaptureImageStoreTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The editor's capture images: loaded once per capture and width, and
/// dropped when there are too many.
@MainActor
@Suite("CaptureImageStore")
struct CaptureImageStoreTests {
    /// Counts loads; every capture loads as a flat image.
    @MainActor
    final class Loads {
        var count = 0
    }

    private func store(_ loads: Loads) -> CaptureImageStore {
        CaptureImageStore { capture, width in
            await MainActor.run { loads.count += 1 }
            return FakeScreenshotsServices.flatImage(width: width, height: width * capture.pixelSize.height / max(1, capture.pixelSize.width))
        }
    }

    private func capture(_ locale: String, slot: Int) -> ScreenshotCapture {
        ScreenshotsSampleData.capture(locale: locale, display: .iPhone, slot: slot)
    }

    @Test func aCaptureLoadsOncePerWidth() async {
        let loads = Loads()
        let store = store(loads)
        let first = capture("en-US", slot: 0)
        #expect(store.image(for: first, width: 500) == nil)
        store.request([first], width: 500)
        store.request([first], width: 500)
        await store.waitUntilLoaded([first], width: 500)
        #expect(store.image(for: first, width: 500)?.width == 500)
        #expect(store.image(for: first, width: 300) == nil)
        #expect(loads.count == 1)
        #expect(store.image(for: nil, width: 500) == nil)
    }

    @Test func tooManyImagesStartOver() async {
        let loads = Loads()
        let store = store(loads)
        let first = capture("en-US", slot: 0)
        store.request([first], width: 100)
        await store.waitUntilLoaded([first], width: 100)
        let many = (0..<CaptureImageStore.limit).map { capture("en-US", slot: $0 % 5) }
        let widths = Array(200..<(200 + CaptureImageStore.limit))
        for (capture, width) in zip(many, widths) {
            store.request([capture], width: width)
        }
        let last = (many.last, widths.last)
        if let capture = last.0, let width = last.1 {
            await store.waitUntilLoaded([capture], width: width)
        }
        #expect(store.image(for: first, width: 100) == nil)
        #expect(store.images.count <= CaptureImageStore.limit)
    }
}
#endif
