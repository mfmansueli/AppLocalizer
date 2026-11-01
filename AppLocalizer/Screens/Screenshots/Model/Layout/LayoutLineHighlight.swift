//
//  LayoutLineHighlight.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The marker bar behind one caption line: the text's width plus the
/// padding on both sides, the line's height, turned about its center.
struct LayoutLineHighlight: Hashable, Sendable {
    var color: TemplateColor
    /// On each side of the text, in pixels.
    var padding: CGFloat
    /// Degrees, clockwise; already alternated per line and mirrored.
    var rotation: Double
    var cornerRadius: CGFloat
    /// Lengths in em of the line's size.
    var shadow: TemplateShadow?
}
