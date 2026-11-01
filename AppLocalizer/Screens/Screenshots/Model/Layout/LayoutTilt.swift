//
//  LayoutTilt.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The device's angle as drawn: a 2D stand-in for a 3D tilt (rotate, skew,
/// scale about the device's center, CSS-style), so a sheet of thumbnails
/// stays cheap to draw. Rotate and turn are already mirrored for
/// right-to-left locales.
struct LayoutTilt: Hashable, Sendable {
    /// Degrees, clockwise.
    var rotate: Double
    /// Degrees around the vertical axis.
    var turn: Double
    /// Degrees back around the horizontal axis.
    var lean: Double
    /// The device's center, in canvas pixels.
    var center: CGPoint

    init(_ tilt: TemplateTilt, isMirrored: Bool, center: CGPoint) {
        let sign: Double = isMirrored ? -1 : 1
        rotate = tilt.rotate * sign
        turn = tilt.turn * sign
        lean = tilt.lean
        self.center = center
    }

    /// `rotate(rz) skewY(−ry × 0.42) skewX(rx × 0.3) scale(cos ry, cos rx)`
    /// about the center, in canvas pixels (y down).
    var transform: CGAffineTransform {
        let radians = Double.pi / 180
        let scale = CGAffineTransform(scaleX: cos(turn * radians), y: cos(lean * radians))
        let skewX = CGAffineTransform(a: 1, b: 0, c: tan(lean * 0.3 * radians), d: 1, tx: 0, ty: 0)
        let skewY = CGAffineTransform(a: 1, b: tan(-turn * 0.42 * radians), c: 0, d: 1, tx: 0, ty: 0)
        let rotation = CGAffineTransform(rotationAngle: rotate * radians)
        return CGAffineTransform(translationX: -center.x, y: -center.y)
            .concatenating(scale).concatenating(skewX).concatenating(skewY).concatenating(rotation)
            .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
    }

    /// How far a device of `size` sticks out above and below its own frame
    /// once rotated and turned, so a caption below it keeps its gap.
    static func lift(for tilt: TemplateTilt, size: CGSize) -> CGFloat {
        let radians = Double.pi / 180
        let rotate = abs(tilt.rotate) * radians
        let turn = abs(tilt.turn) * radians
        let height = Double(size.height)
        let width = Double(size.width)
        return CGFloat(max(0, (height * cos(rotate) + width * sin(rotate) + width * tan(turn * 0.42) - height) / 2))
    }
}
