//
//  ScreenshotImageRenderer.swift
//  AppLocalizer
//

import CoreGraphics
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Renders `ScreenshotView` into images: the upload PNG at the canvas's
/// exact pixel size (scale 1), opaque RGB with the alpha channel stripped,
/// and smaller previews for the grid and the viewer.
@MainActor
enum ScreenshotImageRenderer {
    /// The render at `pixelWidth` pixels wide (the canvas width for the
    /// upload), flattened to opaque RGB.
    static func image(layout: ScreenshotLayout, capture: CGImage?, companion: CGImage? = nil, pixelWidth: Int? = nil) -> CGImage? {
        let canvas = layout.canvas
        let width = pixelWidth ?? canvas.pixelSize.width
        let scale = CGFloat(width) / canvas.width
        let renderer = ImageRenderer(content: ScreenshotView(layout: layout, capture: capture, companion: companion))
        renderer.scale = scale
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(canvas.size)
        guard let image = renderer.cgImage else { return nil }
        let height = Int((canvas.height * scale).rounded())
        return flattened(image, width: width, height: height)
    }

    /// The upload PNG: exactly the canvas's pixel size, RGB, no alpha.
    static func pngData(layout: ScreenshotLayout, capture: CGImage?, companion: CGImage? = nil) -> Data? {
        image(layout: layout, capture: capture, companion: companion).flatMap(ScreenshotPNG.data)
    }

    /// Redraws `image` into an opaque sRGB bitmap of exactly `width` ×
    /// `height` pixels with no alpha channel.
    nonisolated static func flattened(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return nil }
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}
