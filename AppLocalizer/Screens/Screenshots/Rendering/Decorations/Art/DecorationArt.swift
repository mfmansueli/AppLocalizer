//
//  DecorationArt.swift
//  AppLocalizer
//

import SwiftUI

/// A prop's drawing: parts in its own view box, fitted into the
/// decoration's frame whole and centered (SVG's `xMidYMid meet`), or
/// stretched to it (`none`) for marks that follow the frame, like the
/// underline and the corner curve. Strokes scale with the drawing, round
/// capped and joined.
struct DecorationArt: Sendable {
    var viewBox: CGRect
    /// Stretched to the frame instead of fitted whole.
    var stretches: Bool
    var parts: [DecorationArtPart]

    /// From the view box into `frame`.
    func transform(into frame: CGRect) -> CGAffineTransform {
        guard viewBox.width > 0, viewBox.height > 0 else { return .identity }
        var scaleX = frame.width / viewBox.width
        var scaleY = frame.height / viewBox.height
        var origin = frame.origin
        if !stretches {
            let scale = min(scaleX, scaleY)
            scaleX = scale
            scaleY = scale
            origin.x += (frame.width - viewBox.width * scale) / 2
            origin.y += (frame.height - viewBox.height * scale) / 2
        }
        return CGAffineTransform(translationX: -viewBox.minX, y: -viewBox.minY)
            .concatenating(CGAffineTransform(scaleX: scaleX, y: scaleY))
            .concatenating(CGAffineTransform(translationX: origin.x, y: origin.y))
    }

    /// Draws every part into `frame`, the tinted ones in `tint`.
    func draw(in frame: CGRect, tint: TemplateColor, context: inout GraphicsContext) {
        var layer = context
        layer.concatenate(transform(into: frame))
        for part in parts {
            var partLayer = layer
            partLayer.opacity = part.opacity
            if let fill = part.fill {
                partLayer.fill(part.path, with: .color(fill.color(tint: tint).color))
            }
            if let stroke = part.stroke, part.strokeWidth > 0 {
                partLayer.stroke(
                    part.path, with: .color(stroke.color(tint: tint).color),
                    style: StrokeStyle(lineWidth: part.strokeWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
