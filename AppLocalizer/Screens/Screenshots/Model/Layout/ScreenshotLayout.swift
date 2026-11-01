//
//  ScreenshotLayout.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Everything one render draws, resolved from the template for a locale,
/// display type and slot: computed once by `ScreenshotLayoutEngine`, then
/// drawn by `ScreenshotView` and judged by `ScreenshotChecker`. Geometry
/// is in canvas pixels.
struct ScreenshotLayout: Hashable, Sendable {
    var canvas: ScreenshotCanvas
    var locale: String
    var isRightToLeft: Bool
    var isMirrored: Bool
    var background: LayoutBackground
    /// The solid band behind the caption in band placement.
    var band: CGRect?
    var bandColor: TemplateColor?
    /// The reserved caption box: `maxLines × size × lh` per block.
    var captionBox: CGRect
    /// The safe area, for the editor's guides.
    var safeArea: CGRect
    var lines: [LayoutTextLine]
    var device: LayoutDevice?
    /// Where the capture goes.
    var screen: CGRect
    var screenCornerRadius: CGFloat
    /// The screen floats with a shadow (device hidden).
    var screenHasShadow: Bool
    /// The capture fills the canvas (band placement).
    var isFullBleed: Bool
    /// A visionOS window's light rim around the floating screen, in pixels.
    var screenRim: CGFloat = 0
    /// The window bar under a visionOS window.
    var windowBar: CGRect?
    /// Shapes, laurels and badges, behind or in front of the device.
    var decorations: [LayoutDecoration] = []
    var headline: CaptionFit
    var subhead: CaptionFit?
    var headlineFont: FontChoice
    var subheadFont: FontChoice?
    /// The catalog the fonts were measured with; the renderer draws with
    /// the same one.
    var fonts: ScreenshotFontCatalog

    /// Where a capture of `size` is drawn: aspect-fill in the screen,
    /// centered horizontally and top-aligned, clipped to the screen.
    func captureFrame(for size: PixelSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return screen }
        let scale = max(screen.width / CGFloat(size.width), screen.height / CGFloat(size.height))
        let width = CGFloat(size.width) * scale
        let height = CGFloat(size.height) * scale
        return CGRect(x: screen.midX - width / 2, y: screen.minY, width: width, height: height)
    }
}
