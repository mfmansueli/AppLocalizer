//
//  ArtworkRenderer.swift
//  AppLocalizer
//

import CoreGraphics
import SwiftUI

/// Renders the header and search artwork: the upload PNG at Apple's exact
/// size, opaque RGB with no alpha channel, and smaller images for
/// thumbnails.
@MainActor
enum ArtworkRenderer {
    /// The render at `pixelWidth` pixels wide (the artwork's width for the
    /// upload), flattened to opaque RGB.
    static func image(layout: ArtworkLayout, captures: [Int: CGImage], icon: CGImage? = nil, pixelWidth: Int? = nil) -> CGImage? {
        let size = layout.pixelSize
        let width = pixelWidth ?? size.width
        let scale = CGFloat(width) / CGFloat(size.width)
        let renderer = ImageRenderer(content: ArtworkView(layout: layout, captures: captures, icon: icon))
        renderer.scale = scale
        renderer.isOpaque = true
        renderer.proposedSize = ProposedViewSize(layout.size)
        guard let image = renderer.cgImage else { return nil }
        let height = Int((CGFloat(size.height) * scale).rounded())
        return ScreenshotImageRenderer.flattened(image, width: width, height: height)
    }

    /// The upload PNG: exactly Apple's size, RGB, no alpha.
    static func pngData(layout: ArtworkLayout, captures: [Int: CGImage], icon: CGImage? = nil) -> Data? {
        image(layout: layout, captures: captures, icon: icon).flatMap(ScreenshotPNG.data)
    }
}
