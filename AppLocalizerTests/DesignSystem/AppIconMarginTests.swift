//
//  AppIconMarginTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A Mac build's icon sits inside a transparent margin; trimmed to its
/// opaque pixels it fills the tile like an iPhone icon does.
@Suite("App icon margin")
struct AppIconMarginTests {
    /// A `side` × `side` transparent image with `rect` (origin at the top
    /// left) filled at `alpha`.
    static func image(side: Int = 100, filling rects: [(CGRect, CGFloat)]) -> CGImage {
        let context = CGContext(
            data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        for (rect, alpha) in rects {
            context.setFillColor(CGColor(srgbRed: 0.2, green: 0.3, blue: 0.8, alpha: alpha))
            // The context's origin is at the bottom left.
            context.fill(CGRect(x: rect.minX, y: CGFloat(side) - rect.maxY, width: rect.width, height: rect.height))
        }
        return context.makeImage()!
    }

    @Test func theOpaquePixelsAreFoundFromTheTopLeft() {
        let icon = Self.image(filling: [(CGRect(x: 5, y: 10, width: 30, height: 20), 1)])
        #expect(AppIconMargin.opaqueBounds(of: icon) == CGRect(x: 5, y: 10, width: 30, height: 20))
    }

    @Test func aMacIconsMarginIsCroppedAway() {
        let icon = Self.image(filling: [(CGRect(x: 10, y: 10, width: 80, height: 80), 1)])
        let trimmed = AppIconMargin.trimmed(icon)
        #expect(trimmed.width == 80)
        #expect(trimmed.height == 80)
        #expect(AppIconMargin.opaqueBounds(of: trimmed) == CGRect(x: 0, y: 0, width: 80, height: 80))
    }

    @Test func itsFaintShadowIsntPartOfTheIcon() {
        let icon = Self.image(filling: [
            (CGRect(x: 10, y: 8, width: 80, height: 80), 1),
            (CGRect(x: 6, y: 88, width: 88, height: 8), 0.3),
        ])
        let trimmed = AppIconMargin.trimmed(icon)
        #expect(trimmed.width == 80)
        #expect(trimmed.height == 80)
    }

    @Test func anIconThatFillsItsImageIsLeftAsItIs() {
        let icon = Self.image(filling: [(CGRect(x: 0, y: 0, width: 100, height: 100), 1)])
        #expect(AppIconMargin.trimmed(icon) === icon)
        let empty = Self.image(filling: [])
        #expect(AppIconMargin.opaqueBounds(of: empty) == nil)
        #expect(AppIconMargin.trimmed(empty) === empty)
    }

    @Test func artworkThatIsntSquareIsCroppedToASquareInsideTheImage() {
        let icon = Self.image(filling: [(CGRect(x: 0, y: 0, width: 40, height: 20), 1)])
        let trimmed = AppIconMargin.trimmed(icon)
        #expect(trimmed.width == 40)
        #expect(trimmed.height == 40)
        #expect(AppIconMargin.opaqueBounds(of: trimmed) == CGRect(x: 0, y: 0, width: 40, height: 20))
    }

    @Test func aDownloadedIconIsDecodedWithoutItsMargin() throws {
        let png = try #require(ScreenshotPNG.data(Self.image(filling: [(CGRect(x: 10, y: 10, width: 80, height: 80), 1)])))
        let decoded = try #require(AppIconMargin.decodeTrimmed(png))
        #expect(decoded.width == 80)
        #expect(AppIconMargin.decodeTrimmed(Data("not an image".utf8)) == nil)
    }
}
