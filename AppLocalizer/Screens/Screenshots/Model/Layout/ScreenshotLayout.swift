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
    /// What a screen without a capture shows: black (`device.empty`).
    var emptyScreen: TemplateColor? = .black
    /// The capture fills the canvas (band placement).
    var isFullBleed: Bool
    /// A visionOS window's light rim around the floating screen, in pixels.
    var screenRim: CGFloat = 0
    /// The window bar under a visionOS window.
    var windowBar: CGRect?
    /// iPhone Duo's folded cover display beside the inner one (both, side
    /// by side), or a Two phones slot's phone behind, with the companion
    /// capture.
    var companion: LayoutCompanion?
    /// Shapes, laurels, badges and props, behind or in front of the device.
    var decorations: [LayoutDecoration] = []
    /// A Reviews slot: no device or capture, reviews under the headline.
    var reviews: LayoutReviews?
    /// Laurels left out because the app has no App Store rating in the
    /// locale's country yet.
    var unratedLaurels = 0
    var headline: CaptionFit
    var subhead: CaptionFit?
    var headlineFont: FontChoice
    var subheadFont: FontChoice?
    /// The catalog the fonts were measured with; the renderer draws with
    /// the same one.
    var fonts: ScreenshotFontCatalog

    /// What the App Store put in this render, for its render key: the
    /// ratings laurels show, the laurels left out for want of one, and the
    /// reviews quoted. Nil when nothing came from it, so the key stays what
    /// it was. Without the left-out laurels, a render that showed the
    /// template's sample rating before the App Store answered (the same
    /// key) would be used again after it said there's none. A Reviews slot
    /// showing its capture for want of reviews is keyed apart too: Bruma's
    /// Review kept showing the empty slot an earlier build had cached
    /// under the same key, while the push would have sent the capture.
    var storeSignature: String? {
        let ratings = decorations.filter(\.isFromStore).compactMap(\.text)
        guard !ratings.isEmpty || reviews != nil || unratedLaurels > 0 else { return nil }
        let unrated = unratedLaurels > 0 ? ["unrated \(unratedLaurels)"] : []
        let quoted = reviews.map { $0.showsCapture ? "capture for want of reviews" : $0.signature } ?? ""
        return (ratings + unrated + [quoted]).joined(separator: "\u{1D}")
    }

    /// Where a capture of `size` is drawn: aspect-fill in the screen,
    /// centered horizontally and top-aligned, clipped to the screen.
    func captureFrame(for size: PixelSize) -> CGRect {
        Self.captureFrame(for: size, in: screen)
    }

    /// Aspect-fill in `screen`, centered horizontally and top-aligned.
    static func captureFrame(for size: PixelSize, in screen: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return screen }
        let scale = max(screen.width / CGFloat(size.width), screen.height / CGFloat(size.height))
        let width = CGFloat(size.width) * scale
        let height = CGFloat(size.height) * scale
        return CGRect(x: screen.midX - width / 2, y: screen.minY, width: width, height: height)
    }
}
