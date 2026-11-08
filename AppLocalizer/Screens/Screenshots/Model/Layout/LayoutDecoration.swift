//
//  LayoutDecoration.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One decoration as drawn, in canvas pixels, already mirrored for
/// right-to-left locales and moved, narrowed or left out where a
/// language's headline runs into it.
struct LayoutDecoration: Hashable, Sendable {
    var kind: TemplateDecoration.Kind
    /// For `kind == .shape`.
    var shape: TemplateDecoration.Shape?
    /// For `kind == .art`.
    var art: TemplateArt?
    var frame: CGRect
    /// Degrees, clockwise, about the frame's center.
    var rotation: Double
    /// A shape or prop drawn flipped left to right; text never flips.
    var isFlipped: Bool
    var opacity: Double
    var color: TemplateColor
    /// In front of the device and the band, under the caption.
    var isFront: Bool
    /// A laurel's or badge's value.
    var text: String?
    var textColor: TemplateColor
    var fontName: String
    var textSize: CGFloat
    var textWeight: Int
    /// The color of a laurel's five stars; nil for none.
    var starColor: TemplateColor?
    var starSize: CGFloat
    var starGap: CGFloat
    /// A laurel showing the App Store's rating rather than the template's
    /// value.
    var isFromStore = false

    /// The rating a laurel or badge shows.
    var ratingValue: Double? {
        guard kind != .shape, let text else { return nil }
        return TemplateDecoration.number(in: text)
    }
}
