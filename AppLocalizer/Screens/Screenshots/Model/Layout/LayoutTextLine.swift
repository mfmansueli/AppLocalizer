//
//  LayoutTextLine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One caption line, already broken: the renderer draws it as is and never
/// re-wraps it. Geometry is in canvas pixels.
struct LayoutTextLine: Hashable, Sendable {
    var text: String
    var fontName: String
    var weight: Int
    var pixelSize: CGFloat
    /// The line box: the caption box's width, `size × lh` high.
    var frame: CGRect
    var alignment: LayoutTextAlignment
    var color: TemplateColor
    /// Letter spacing in pixels.
    var tracking: CGFloat
    var isRightToLeft: Bool
    /// Past `maxLines`: drawn dimmed so the overflow shows.
    var isOverflow: Bool
}
