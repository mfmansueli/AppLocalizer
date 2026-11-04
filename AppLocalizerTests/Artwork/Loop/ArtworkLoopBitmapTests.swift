//
//  ArtworkLoopBitmapTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A loop's still layers made ready once: in the movie's own pixel format,
/// the phones and the text cut to where they are, every pixel kept (a
/// hairline far from the rest too), and each frame drawn from them the same
/// as from the whole layers.
/// Off the main actor: the frames are big, and other tests wait on it.
@Suite("Artwork loop layers made ready")
struct ArtworkLoopBitmapTests {
    /// A `width` × `height` image on clear, in RGBA (not the movie's
    /// format), with `rects` (top-left origin) filled.
    private static func image(width: Int, height: Int, opaque: Bool = false, rects: [CGRect]) -> CGImage? {
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        if opaque {
            context.setFillColor(CGColor(srgbRed: 0.1, green: 0.2, blue: 0.5, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        context.setFillColor(CGColor(srgbRed: 1, green: 0.4, blue: 0.1, alpha: 0.9))
        for rect in rects {
            context.fill(CGRect(x: rect.minX, y: CGFloat(height) - rect.maxY, width: rect.width, height: rect.height))
        }
        return context.makeImage()
    }

    @Test func aLayerOnClearIsCutToItsContent() throws {
        let layer = try #require(Self.image(width: 100, height: 80, rects: [CGRect(x: 30, y: 20, width: 10, height: 6)]))
        let ready = try #require(ArtworkLoopBitmap.prepare(layer, opaque: false))
        let margin = CGFloat(ArtworkLoopBitmap.margin)
        #expect(ready.bounds == CGRect(x: 30 - margin, y: 20 - margin, width: 10 + margin * 2, height: 6 + margin * 2))
        #expect(ready.image.width == Int(ready.bounds.width))
        #expect(ready.image.height == Int(ready.bounds.height))
        #expect(ready.image.bitmapInfo.rawValue & CGBitmapInfo.alphaInfoMask.rawValue == CGImageAlphaInfo.premultipliedFirst.rawValue)
        #expect(ready.image.byteOrderInfo == .order32Little, "The movie's own BGRA")
    }

    /// One pixel row at the bottom edge, far from the rest, is kept.
    @Test func aHairlineFarFromTheRestIsKept() throws {
        let layer = try #require(Self.image(width: 120, height: 90, rects: [
            CGRect(x: 10, y: 10, width: 20, height: 20), CGRect(x: 0, y: 89, width: 120, height: 1),
        ]))
        let bounds = try #require(ArtworkLoopBitmap.prepare(layer, opaque: false)?.bounds)
        #expect(bounds == CGRect(x: 0, y: 10 - CGFloat(ArtworkLoopBitmap.margin), width: 120, height: 80 + CGFloat(ArtworkLoopBitmap.margin)))
    }

    @Test func anEmptyLayerIsDropped() throws {
        let layer = try #require(Self.image(width: 40, height: 30, rects: []))
        #expect(ArtworkLoopBitmap.prepare(layer, opaque: false) == nil)
    }

    @Test func theBackgroundKeepsTheWholeFrame() throws {
        let layer = try #require(Self.image(width: 64, height: 48, opaque: true, rects: []))
        let ready = try #require(ArtworkLoopBitmap.prepare(layer, opaque: true))
        #expect(ready.bounds == CGRect(x: 0, y: 0, width: 64, height: 48))
        #expect(ready.image.width == 64 && ready.image.height == 48)
    }

    @Test func theCutGoesWhereCoreGraphicsDrawsIt() {
        // 10 from the top of 80, 20 tall: 50 from the bottom.
        #expect(ArtworkLoopBitmap.flipped(CGRect(x: 5, y: 10, width: 30, height: 20), height: 80) == CGRect(x: 5, y: 50, width: 30, height: 20))
    }

    /// A frame drawn from the layers made ready is the frame drawn from the
    /// whole layers, the phones floating a fraction of a pixel included.
    @Test func aFrameIsTheSameFromTheCutLayers() async throws {
        let layout = await MainActor.run { ArtworkCheckFixtures.layout(.header, headline: "Your week, sorted", isMotion: true) }
        let width = layout.pixelSize.width
        let height = layout.pixelSize.height
        let background = try #require(Self.image(width: width, height: height, opaque: true, rects: []))
        let phones = try #require(Self.image(width: width, height: height, rects: [
            CGRect(x: width / 2, y: height / 5, width: width / 5, height: height * 3 / 4),
        ]))
        let text = try #require(Self.image(width: width, height: height, rects: [
            CGRect(x: width / 12, y: height / 3, width: width / 3, height: height / 9), CGRect(x: width / 12, y: height - 3, width: width / 3, height: 1),
        ]))
        let whole = ArtworkLoopLayers(background: background, phones: phones, text: text)
        let ready = try #require(ArtworkLoopLayers.prepared(background: background, phones: phones, text: text))
        #expect(ready.phonesFrame != nil && ready.textFrame != nil)
        for phase in [0.0, 0.13, 0.5] {
            let one = try #require(Self.frame(whole, layout: layout, phase: phase))
            let other = try #require(Self.frame(ready, layout: layout, phase: phase))
            #expect(one.count == other.count)
            // Every 13th byte: each channel of a pixel in turn, and quick.
            let largest = stride(from: 0, to: one.count, by: 13).reduce(0) { max($0, abs(Int(one[$1]) - Int(other[$1]))) }
            #expect(largest <= 2, "At \(phase) a channel differs by \(largest)")
        }
    }

    /// Frame `phase` of `layers`, drawn like the movie's pixel buffers.
    private static func frame(_ layers: ArtworkLoopLayers, layout: ArtworkLayout, phase: Double) -> [UInt8]? {
        let width = layout.pixelSize.width
        let height = layout.pixelSize.height
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: ArtworkLoopBitmap.bitmapInfo
        ), let data = context.data else { return nil }
        context.interpolationQuality = .high
        layers.draw(layout, phase: phase, in: context)
        return Array(UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: width * height * 4))
    }
}
#endif
