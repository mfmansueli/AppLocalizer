//
//  DuoInnerDisplayTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import AppLocalizer

/// Telling iPhone Duo's inner display apart from the helper's small
/// screenshot (180 × 256): black while it's closed, a faint spinner in the
/// middle while it starts or is stuck, anything else once it's open. The
/// levels are a real stuck Duo's: the spinner's frames light 17 to 28
/// pixels, some no brighter than 26 of 255.
@Suite("iPhone Duo's inner display")
struct DuoInnerDisplayTests {
    /// A black 180 × 256 screenshot, with `light` drawing on it.
    private static func image(_ light: (CGContext) -> Void = { _ in }) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 180, height: 256, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 180, height: 256))
        light(context)
        return try #require(context.makeImage())
    }

    private static func fill(_ rect: CGRect, gray: CGFloat) -> (CGContext) -> Void {
        { context in
            context.setFillColor(CGColor(gray: gray, alpha: 1))
            context.fill(rect)
        }
    }

    @Test func closedIsBlack() throws {
        #expect(try DuoInnerDisplay(Self.image()) == .black)
    }

    @Test func aFaintSpinnerInTheMiddleIsTheSpinner() throws {
        // 5 × 4 pixels at 26 of 255, where a stuck Duo's spinner was.
        #expect(try DuoInnerDisplay(Self.image(Self.fill(CGRect(x: 88, y: 126, width: 5, height: 4), gray: 26 / 255))) == .spinner)
        #expect(try DuoInnerDisplay(Self.image(Self.fill(CGRect(x: 87, y: 125, width: 6, height: 6), gray: 0.45))) == .spinner)
    }

    @Test func aDarkAppIsShowing() throws {
        // Alba's night sky is dark, but nowhere near black.
        #expect(try DuoInnerDisplay(Self.image { context in
            context.setFillColor(CGColor(red: 0.2, green: 0.17, blue: 0.36, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: 180, height: 256))
        }) == .showing)
    }

    @Test func lightAwayFromTheMiddleIsShowing() throws {
        // A status bar's clock, on an otherwise black app.
        #expect(try DuoInnerDisplay(Self.image(Self.fill(CGRect(x: 10, y: 240, width: 12, height: 6), gray: 1))) == .showing)
    }

    @Test func moreThanASpinnerInTheMiddleIsShowing() throws {
        // A black app's centered card: over 1% of the screen.
        #expect(try DuoInnerDisplay(Self.image(Self.fill(CGRect(x: 70, y: 110, width: 30, height: 30), gray: 0.6))) == .showing)
    }

    @Test func theHelpersBase64IsRead() throws {
        let context = try #require(CGContext(
            data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let png = try #require(Self.png(context.makeImage()))
        #expect(DuoInnerDisplay(base64: png.base64EncodedString() + "\n") == .black)
        #expect(DuoInnerDisplay(base64: "") == nil)
        #expect(DuoInnerDisplay(base64: "Wrote screenshot to: /tmp/x.png") == nil)
    }

    private static func png(_ image: CGImage?) -> Data? {
        guard let image else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? data as Data : nil
    }
}
