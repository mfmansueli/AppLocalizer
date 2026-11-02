//
//  CaptureImageStoreTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The editors' and Captures tab's capture images: loaded once per capture
/// and width; past the pixel budget, the ones asked for longest ago go.
@MainActor
@Suite("CaptureImageStore")
struct CaptureImageStoreTests {
    /// Counts loads; every capture loads as a flat image.
    @MainActor
    final class Loads {
        var count = 0
    }

    private func store(_ loads: Loads, pixelBudget: Int = CaptureImageStore.pixelBudget) -> CaptureImageStore {
        CaptureImageStore(pixelBudget: pixelBudget) { capture, width in
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

    /// Past the budget, the image asked for longest ago goes; one asked
    /// for again counts as new, and one that went loads again when asked.
    @Test func theOldestImagesGoFirstPastTheBudget() async {
        let loads = Loads()
        // Two 100-px-wide iPhone captures (100 × 217) fit, three don't.
        let store = store(loads, pixelBudget: 50000)
        let (first, second, third) = (capture("en-US", slot: 0), capture("en-US", slot: 1), capture("en-US", slot: 2))
        for capture in [first, second] {
            store.request([capture], width: 100)
            await store.waitUntilLoaded([capture], width: 100)
        }
        store.request([first], width: 100)
        store.request([third], width: 100)
        await store.waitUntilLoaded([third], width: 100)
        #expect(store.image(for: first, width: 100) != nil)
        #expect(store.image(for: second, width: 100) == nil)
        #expect(store.images.count == 2)
        #expect(loads.count == 3)

        store.request([second], width: 100)
        await store.waitUntilLoaded([second], width: 100)
        #expect(loads.count == 4)
        #expect(store.image(for: first, width: 100) == nil)
    }

    /// The Captures tab asks for every thumbnail row by row: 14 locales of
    /// 5 captures all stay, none blank.
    @Test func aWholeCoverageOfThumbnailsStaysLoaded() async {
        let loads = Loads()
        let store = store(loads)
        let locales = ["en-US", "ar-SA", "zh-Hans", "nl-NL", "fr-FR", "de-DE", "it", "ja", "ko", "pt-BR", "es-ES", "sv", "th", "vi"]
        let rows = locales.map { locale in (0..<5).map { capture(locale, slot: $0) } }
        rows.forEach { store.request($0, width: 80) }
        let all = rows.flatMap(\.self)
        await store.waitUntilLoaded(all, width: 80)
        #expect(all.allSatisfy { store.image(for: $0, width: 80) != nil })
        #expect(loads.count == 70)
    }

    /// The newest image stays even when it alone is over the budget.
    @Test func theNewestImageStaysHoweverBig() async {
        let store = store(Loads(), pixelBudget: 1000)
        let first = capture("en-US", slot: 0)
        store.request([first], width: 100)
        await store.waitUntilLoaded([first], width: 100)
        #expect(store.image(for: first, width: 100) != nil)
    }
}
#endif
