//
//  ExtrasFileThumbnail.swift
//  AppLocalizer
//

import ImageIO
import SwiftUI

/// A made header, search image or App Preview, small: the PNG read as a
/// thumbnail, a play tile for a movie, a dashed box while there's none.
struct ExtrasFileThumbnail: View {
    let url: URL?
    let pixelSize: PixelSize
    var width: CGFloat = 96
    /// The tallest it gets: a portrait App Preview narrows to fit.
    var maxHeight: CGFloat = .infinity

    @State private var image: CGImage?

    var body: some View {
        let size = Self.size(of: pixelSize, width: width, maxHeight: maxHeight)
        ZStack {
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
            } else if url?.pathExtension == "mov" {
                Palette.fill2
                Image(systemName: "play.rectangle").foregroundStyle(Palette.label2)
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Palette.separator2, style: StrokeStyle(lineWidth: 1, dash: [3]))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .task(id: url) { image = await Self.thumbnail(url, maxPixels: Int(max(size.width, size.height) * 3)) }
        .accessibilityHidden(true)
    }

    /// `pixelSize` scaled to `width`, or narrower to stay under
    /// `maxHeight`.
    static func size(of pixelSize: PixelSize, width: CGFloat, maxHeight: CGFloat) -> CGSize {
        let aspect = CGFloat(pixelSize.height) / CGFloat(max(1, pixelSize.width))
        let height = width * aspect
        guard height > maxHeight else { return CGSize(width: width, height: height) }
        return CGSize(width: maxHeight / max(aspect, 0.001), height: maxHeight)
    }

    /// The PNG at about `maxPixels` on its long side, read off the main
    /// thread; nil for a movie or a missing file.
    static func thumbnail(_ url: URL?, maxPixels: Int) async -> CGImage? {
        guard let url, url.pathExtension.lowercased() == "png" else { return nil }
        return await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixels,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ]
            return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }.value
    }
}
