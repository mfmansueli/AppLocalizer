//
//  StarterPreview.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A gallery card: the template's first five slots rendered with the
/// primary locale's captions and captures, and which scripts its font
/// draws.
struct StarterPreview: Identifiable, Hashable, Sendable {
    var starter: TemplateStarter
    var jobs: [RenderJob]
    /// "Anton (bundled) draws Latin, Vietnamese. Japanese uses a fallback
    /// font."
    var fontNote: String

    var id: TemplateStarter { starter }

    /// The slots a card shows.
    static let slotCount = 5
    /// The card's thumbnails, in points.
    static let thumbnailWidth = 46
    /// Rendered at twice the thumbnails' width.
    static let pixelWidth = thumbnailWidth * 2

    static var thumbnailHeight: CGFloat {
        let size = ScreenshotDisplayType.iPhone.portraitPixelSize
        return (CGFloat(thumbnailWidth) * CGFloat(size.height) / CGFloat(size.width)).rounded()
    }
}
