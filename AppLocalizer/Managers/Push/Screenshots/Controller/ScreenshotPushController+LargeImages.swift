//
//  ScreenshotPushController+LargeImages.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Review & Push's viewer: an image a push would send, or the live one it
/// replaces, at the size the viewer draws it, rather than the thumbnails'.
extension ScreenshotPushController {
    /// The new image `pixelWidth` wide: rendered again at that size, or the
    /// kept file decoded at it.
    func largeNewImage(for item: ScreenshotPlanItem, pixelWidth: Int) async -> CGImage? {
        switch item.content {
        case let .render(job):
            return await renderQueue(appID: item.appID, displayType: item.cell.displayType)?.largeImage(for: job, pixelWidth: pixelWidth)
        case let .restore(image):
            guard let data = try? workspace?.pushing?.backups.data(for: image, appID: item.appID) else { return nil }
            let longSide = Self.longSide(of: image.pixelSize, width: pixelWidth)
            return await Task.detached(priority: .userInitiated) { ScreenshotThumbnailer.thumbnail(data, maxPixelSize: longSide) }.value
        }
    }

    /// The live screenshot `pixelWidth` wide; nil when nothing's live
    /// there.
    func largeOldImage(for item: ScreenshotPlanItem, pixelWidth: Int) async -> CGImage? {
        guard let old = item.old else { return nil }
        return await renderQueue(appID: item.appID, displayType: item.cell.displayType)?.largeLiveImage(old, pixelWidth: pixelWidth)
    }

    /// The long side of an image `width` pixels wide at `size`'s
    /// proportions: what ImageIO's thumbnails are sized by.
    static func longSide(of size: PixelSize?, width: Int) -> Int {
        guard let size, size.width > 0, size.height > 0 else { return width }
        return max(width, Int((Double(width) * Double(size.height) / Double(size.width)).rounded()))
    }
}
