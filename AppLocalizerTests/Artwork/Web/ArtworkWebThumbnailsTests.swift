//
//  ArtworkWebThumbnailsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The pages drawn small stay while the app runs, the oldest going first;
/// a page's text fit reads in Captions like the built-in layout's.
@MainActor
@Suite("Claude Design pages drawn small")
struct ArtworkWebThumbnailsTests {
    private func key(_ locale: String, width: Int = 600) -> ArtworkWebThumbnails.Key {
        ArtworkWebThumbnails.Key(html: "<p>x</p>", locale: locale, headline: "Calm", appName: "Alba", captures: [:], pixelWidth: width)
    }

    private var image: CGImage {
        let context = CGContext(
            data: nil, width: 2, height: 2, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        return context.makeImage()!
    }

    @Test func theOldestGoFirst() {
        let cache = ArtworkWebThumbnails(limit: 2)
        cache.store(image, for: key("en-US"))
        cache.store(image, for: key("de-DE"))
        cache.store(image, for: key("de-DE"))
        #expect(cache.count == 2)
        cache.store(image, for: key("ja"))
        #expect(cache.count == 2)
        #expect(cache.image(for: key("en-US")) == nil)
        #expect(cache.image(for: key("de-DE")) != nil)
        #expect(cache.image(for: key("ja")) != nil)
        #expect(cache.image(for: key("ja", width: 300)) == nil, "Another size is another image")
    }

    @Test func aPagesFitReadsInPixels() {
        var element = ArtworkWebMeasure.Element(marker: "headline", x: 0, y: 0, width: 10, height: 10, text: "Calm", fits: true, isVisible: true)
        element.fontSize = 220
        element.fitScale = 1
        #expect(element.captionFit.tone == .fits)
        #expect(ArtworkTextCell.label(element.captionFit) == "Fits at 220 px")

        element.fontSize = 110
        element.fitScale = 0.5
        let shrunk = CaptionsViewModel.meterFit(element.captionFit)
        #expect(shrunk.tone == .shrinks)
        #expect(shrunk.fullSize == 220)
        #expect(ArtworkTextCell.label(shrunk) == "Shrinks to 110 px")

        element.fits = false
        let long = CaptionsViewModel.meterFit(element.captionFit)
        #expect(long.tone == .overflows)
        #expect(long.fill > 1)
        #expect(ArtworkTextCell.label(long) == "Too long at 110 px")
    }
}
#endif
