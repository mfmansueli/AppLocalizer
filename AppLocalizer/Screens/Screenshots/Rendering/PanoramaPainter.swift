//
//  PanoramaPainter.swift
//  AppLocalizer
//

import SwiftUI

/// Draws the panorama starter's picture: a horizontal gradient across all
/// slots with soft circles and two waves, of which a slot shows its own
/// window. Mirrored in right-to-left locales, keeping the slot order. The
/// header and search artwork draw the whole picture, so they carry on the
/// screenshots' look.
struct PanoramaPainter {
    let panorama: LayoutPanorama
    /// One slot's canvas: a screenshot's, or a share of the artwork's
    /// width at its height.
    let slotSize: CGSize

    init(panorama: LayoutPanorama, canvas: ScreenshotCanvas) {
        self.panorama = panorama
        slotSize = canvas.size
    }

    init(panorama: LayoutPanorama, slotSize: CGSize) {
        self.panorama = panorama
        self.slotSize = slotSize
    }

    /// The panorama's slot, filling a slot-sized canvas.
    func draw(in context: inout GraphicsContext) {
        draw(in: &context, window: CGRect(origin: .zero, size: slotSize), offset: CGFloat(panorama.slot) * slotSize.width)
    }

    /// Every slot side by side, from the leading edge.
    func drawPicture(in context: inout GraphicsContext) {
        let total = slotSize.width * CGFloat(max(1, panorama.slotCount))
        draw(in: &context, window: CGRect(x: 0, y: 0, width: total, height: slotSize.height), offset: 0)
    }

    private func draw(in context: inout GraphicsContext, window: CGRect, offset: CGFloat) {
        let width = slotSize.width
        let height = slotSize.height
        let total = width * CGFloat(max(1, panorama.slotCount))
        context.drawLayer { layer in
            layer.clip(to: Path(window))
            layer.translateBy(x: -offset, y: 0)
            if panorama.isMirrored {
                layer.translateBy(x: total, y: 0)
                layer.scaleBy(x: -1, y: 1)
            }
            let rect = CGRect(x: 0, y: 0, width: total, height: height)
            layer.fill(Path(rect), with: .linearGradient(
                Gradient(colors: panorama.stops.map(\.color)), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: total, y: 0)
            ))
            for circle in circles(width: width, height: height) {
                layer.fill(Path(ellipseIn: circle.rect), with: .color(circle.color))
            }
            layer.stroke(
                wave(amplitude: height * 0.05, baseline: height * 0.74, phase: 1, total: total),
                with: .color(.white.opacity(0.5)), lineWidth: width * 0.12
            )
            layer.stroke(
                wave(amplitude: height * 0.035, baseline: height * 0.83, phase: -1, total: total),
                with: .color(Color(.sRGB, red: 91 / 255, green: 84 / 255, blue: 232 / 255, opacity: 0.22)), lineWidth: width * 0.035
            )
        }
    }

    /// A soft disc on the panorama, in canvas units.
    private struct Disc {
        var center: CGPoint
        var diameter: CGFloat
        var color: Color

        var rect: CGRect {
            CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
        }
    }

    private func circles(width: CGFloat, height: CGFloat) -> [Disc] {
        [
            Disc(center: CGPoint(x: width * 0.48, y: height * 0.2), diameter: width, color: .white.opacity(0.55)),
            Disc(center: CGPoint(x: width * 2.7, y: height * 0.62), diameter: width * 0.62, color: .white.opacity(0.4)),
            Disc(
                center: CGPoint(x: width * 3.9, y: height * 0.12), diameter: width * 0.8,
                color: Color(.sRGB, red: 1, green: 214 / 255, blue: 190 / 255, opacity: 0.55)
            ),
        ]
    }

    private func wave(amplitude: CGFloat, baseline: CGFloat, phase: CGFloat, total: CGFloat) -> Path {
        let step = slotSize.width * 0.9
        var path = Path()
        path.move(to: CGPoint(x: 0, y: baseline))
        var x: CGFloat = 0
        var index = 0
        while x < total + step {
            let sign: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            path.addQuadCurve(to: CGPoint(x: x + step, y: baseline), control: CGPoint(x: x + step / 2, y: baseline + amplitude * sign * phase))
            x += step
            index += 1
        }
        return path
    }
}
