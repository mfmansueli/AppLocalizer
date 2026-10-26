//
//  ScreenshotRenderTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Renders are Apple's exact pixel sizes, PNG, opaque RGB; the render key
/// changes with anything that changes the image and nothing else.
@MainActor
@Suite("Screenshot rendering")
struct ScreenshotRenderTests {
    private let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts)

    private func layout(_ display: ScreenshotDisplayType) -> ScreenshotLayout {
        engine.layout(
            ScreenshotsSampleData.template, slot: 0, locale: .englishUS, displayType: display,
            caption: ScreenshotsTestFixtures.caption("en-US", slot: 0)
        )
    }

    @Test func theIPhoneUploadIsExactly1320By2868WithoutAlpha() throws {
        let capture = FakeScreenshotsServices.flatImage(width: 660, height: 1434)
        let data = try #require(ScreenshotImageRenderer.pngData(layout: layout(.iPhone), capture: capture))
        let image = try #require(ScreenshotPNG.image(data))
        #expect(image.width == 1320)
        #expect(image.height == 2868)
        let hasAlpha = ScreenshotPNG.hasAlpha(data)
        #expect(hasAlpha == false)
    }

    @Test func aPNGWithAnAlphaChannelIsCaught() throws {
        let context = try #require(CGContext(
            data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = try #require(context.makeImage())
        let data = try #require(ScreenshotPNG.data(image))
        let hasAlpha = ScreenshotPNG.hasAlpha(data)
        #expect(hasAlpha)
        let notAPNG = ScreenshotPNG.hasAlpha(Data("not a png".utf8))
        #expect(notAPNG)
    }

    @Test func theIPadUploadIsLandscape2752By2064() throws {
        let image = try #require(ScreenshotImageRenderer.image(layout: layout(.iPad), capture: nil))
        #expect(image.width == 2752)
        #expect(image.height == 2064)
    }

    @Test func thumbnailsKeepTheAspectRatio() throws {
        let image = try #require(ScreenshotImageRenderer.image(layout: layout(.iPhone), capture: nil, pixelWidth: 184))
        #expect(image.width == 184)
        #expect(image.height == 400)
    }

    @Test func theChecksumIsStableForTheSameBytes() {
        let data = Data("same bytes".utf8)
        #expect(ScreenshotPNG.checksum(data) == ScreenshotPNG.checksum(Data("same bytes".utf8)))
        #expect(ScreenshotPNG.checksum(data) != ScreenshotPNG.checksum(Data("other".utf8)))
    }

    @Test func theRenderKeyFollowsTheCaptionTextButNotItsProvenance() {
        let hash = ScreenshotsSampleData.template.contentHash
        let written = ScreenshotCaption(headline: "Write a little", provenance: .written)
        let reviewed = ScreenshotCaption(headline: "Write a little", provenance: .reviewed)
        let changed = ScreenshotCaption(headline: "Write a lot", provenance: .written)
        func key(_ caption: ScreenshotCaption) -> RenderKey {
            RenderKey(templateHash: hash, locale: "en-US", displayType: .iPhone, slot: 0, caption: caption, captureID: "c1")
        }
        #expect(key(written) == key(reviewed))
        #expect(key(written) != key(changed))
    }

    @Test func theCacheKeepsRendersInMemoryWithoutADirectory() async throws {
        let cache = ScreenshotRenderCache(directory: nil, limit: 1)
        let image = try #require(FakeScreenshotsServices.flatImage(width: 4, height: 8))
        let first = RenderKey(rawValue: "a")
        let second = RenderKey(rawValue: "b")
        cache.store(image, key: first, width: 4)
        #expect(cache.cached(first, width: 4) != nil)
        #expect(cache.cached(first, width: 8) == nil)
        cache.store(image, key: second, width: 4)
        #expect(cache.cached(first, width: 4) == nil)
        #expect(await cache.load(second, width: 4) != nil)
    }
}
#endif
