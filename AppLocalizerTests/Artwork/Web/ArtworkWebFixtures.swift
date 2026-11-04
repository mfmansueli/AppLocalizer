//
//  ArtworkWebFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
@testable import AppLocalizer

/// Claude Design pages for the web renderer's tests: a search page on a
/// flat background with the headline in a box, the name, the icon and one
/// capture, and what fills them in.
enum ArtworkWebFixtures {
    /// The background: a flat navy, easy to find in the pixels.
    static let background = TemplateColor(red: 0x20 / 255, green: 0x30 / 255, blue: 0x40 / 255)

    /// A search page (3840 × 2560): the headline at (200, 300) in a 1600 ×
    /// 400 box that shrinks to fit, the name under it, the capture on the
    /// trailing side, and `extra` CSS and body HTML.
    static func searchPage(extraCSS: String = "", extraBody: String = "", fit: Bool = true) -> String {
        """
        <!doctype html><html><head><style>
        html, body { margin: 0; width: 3840px; height: 2560px; overflow: hidden; background: #203040; }
        h1 { position: absolute; left: 200px; top: 300px; width: 1600px; height: 400px; margin: 0;
             font: 700 200px/1.0 system-ui; color: #ffffff; }
        .name { position: absolute; left: 200px; top: 2200px; width: 1600px; font: 600 90px system-ui; color: #ffffff; }
        .icon { position: absolute; left: 200px; top: 2000px; width: 160px; height: 160px; }
        .phone { position: absolute; inset-inline-end: 400px; top: 300px; width: 900px; height: 1956px; }
        .phone img { width: 100%; height: 100%; object-fit: cover; }
        \(extraCSS)
        </style></head><body>
        <h1 data-al="headline"\(fit ? " data-al-fit" : "")>Placeholder</h1>
        <img class="icon" data-al="icon">
        <div class="name" data-al="appName">Name</div>
        <div class="phone"><img data-al="capture" data-slot="1"></div>
        \(extraBody)
        </body></html>
        """
    }

    /// A solid-color PNG, `width` × `height`.
    static func png(width: Int = 60, height: Int = 130, red: Double = 0.9, green: Double = 0.3, blue: Double = 0.2) -> Data {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(srgbRed: red, green: green, blue: blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return ScreenshotPNG.data(context.makeImage()!)!
    }

    static func request(
        _ html: String = searchPage(), headline: String = "Gentle daily quotes", locale: String = "en-US", isRightToLeft: Bool = false,
        kind: AutopilotArtworkKind = .search, pixelWidth: Int? = 960, time: Double = 0, primary: String? = "en-US",
        phrases: [String: String] = [:]
    ) -> ArtworkWebRequest {
        ArtworkWebRequest(
            html: html, kind: kind, locale: locale, isRightToLeft: isRightToLeft, headline: headline, appName: "Alba",
            captures: [0: png()], icon: png(width: 64, height: 64, red: 0.2, green: 0.8, blue: 0.3), time: time, pixelWidth: pixelWidth,
            primaryLocale: primary, phrases: phrases
        )
    }

    /// The color at (`x`, `y`) in canvas pixels of an image `request` drew.
    static func color(in image: CGImage, x: Double, y: Double, canvasWidth: Int = 3840) -> TemplateColor {
        let pixels = ArtworkPixels(image)!
        let scale = Double(pixels.width) / Double(canvasWidth)
        return pixels.color(x: Int(x * scale), y: Int(y * scale))
    }

    static func isClose(_ first: TemplateColor, _ second: TemplateColor, within tolerance: Double = 0.05) -> Bool {
        abs(first.red - second.red) <= tolerance && abs(first.green - second.green) <= tolerance && abs(first.blue - second.blue) <= tolerance
    }
}
#endif
