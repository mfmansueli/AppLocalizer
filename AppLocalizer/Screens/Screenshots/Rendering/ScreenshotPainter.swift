//
//  ScreenshotPainter.swift
//  AppLocalizer
//

import CoreText
import SwiftUI

/// Draws a `ScreenshotLayout` into a SwiftUI graphics context, in canvas
/// pixels: background, the decorations behind, the capture (in its device
/// frame, tilted when the device has an angle, floating, or full bleed
/// under the band), the band, the decorations in front, then the
/// pre-broken caption lines. Lines are drawn exactly as the layout broke
/// them; nothing re-wraps.
struct ScreenshotPainter {
    let layout: ScreenshotLayout
    let capture: CGImage?

    /// The screen color where there's no capture yet.
    static let emptyScreen = Color(white: 0.11)

    func draw(in context: inout GraphicsContext) {
        let canvasRect = CGRect(origin: .zero, size: layout.canvas.size)
        drawBackground(in: &context, rect: canvasRect)
        let decorations = DecorationPainter(layout: layout)
        decorations.draw(front: false, in: &context)
        if layout.isFullBleed {
            drawCapture(in: &context, clip: Path(canvasRect))
            if let band = layout.band {
                context.fill(Path(band), with: .color(layout.bandColor?.color ?? .black))
            }
        } else if let device = layout.device {
            drawDevice(device, in: &context)
        } else {
            drawFloatingScreen(in: &context)
        }
        decorations.draw(front: true, in: &context)
        CaptionLinePainter(layout: layout).draw(in: &context)
    }

    // MARK: - Background

    private func drawBackground(in context: inout GraphicsContext, rect: CGRect) {
        switch layout.background {
        case let .solid(color):
            context.fill(Path(rect), with: .color(color.color))
        case let .linear(angle, stops):
            let (start, end) = Self.gradientPoints(angle: angle, in: rect)
            context.fill(Path(rect), with: .linearGradient(Gradient(colors: stops.map(\.color)), startPoint: start, endPoint: end))
        case let .panorama(panorama):
            PanoramaPainter(panorama: panorama, canvas: layout.canvas).draw(in: &context)
        }
    }

    /// CSS `linear-gradient(<angle>deg, …)`: 0° runs bottom to top, 90°
    /// left to right, and the line is long enough that the corners get
    /// the end colors.
    static func gradientPoints(angle: Double, in rect: CGRect) -> (CGPoint, CGPoint) {
        let radians = angle * .pi / 180
        let direction = CGVector(dx: sin(radians), dy: -cos(radians))
        let length = abs(rect.width * direction.dx) + abs(rect.height * direction.dy)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let half = CGVector(dx: direction.dx * length / 2, dy: direction.dy * length / 2)
        return (CGPoint(x: center.x - half.dx, y: center.y - half.dy), CGPoint(x: center.x + half.dx, y: center.y + half.dy))
    }

    // MARK: - Device and capture

    private func drawDevice(_ device: LayoutDevice, in parent: inout GraphicsContext) {
        var context = parent
        if let tilt = device.tilt { context.concatenate(tilt.transform) }
        let body = Path(roundedRect: device.frame, cornerRadius: device.cornerRadius, style: .continuous)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.28), radius: device.shadowRadius / 2, x: 0, y: device.shadowOffset))
            layer.fill(body, with: .color(device.color.color))
        }
        let rimWidth = max(2, device.bezel * 0.12)
        context.stroke(
            Path(roundedRect: device.frame.insetBy(dx: rimWidth / 2, dy: rimWidth / 2), cornerRadius: device.cornerRadius, style: .continuous),
            with: .color(.white.opacity(0.14)), lineWidth: rimWidth
        )
        let screen = Path(roundedRect: layout.screen, cornerRadius: layout.screenCornerRadius, style: .continuous)
        drawCapture(in: &context, clip: screen)
        if let island = device.island {
            context.fill(Path(roundedRect: island, cornerRadius: island.height / 2, style: .continuous), with: .color(.black))
        }
    }

    private func drawFloatingScreen(in context: inout GraphicsContext) {
        let screen = Path(roundedRect: layout.screen, cornerRadius: layout.screenCornerRadius, style: .continuous)
        let height = layout.canvas.height
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.28), radius: height * 0.02, x: 0, y: height * 0.012))
            layer.fill(screen, with: .color(Self.emptyScreen))
        }
        drawCapture(in: &context, clip: screen)
        if layout.screenRim > 0 {
            context.stroke(screen, with: .color(.white.opacity(0.55)), lineWidth: layout.screenRim)
        }
        if let bar = layout.windowBar {
            context.fill(Path(roundedRect: bar, cornerRadius: bar.height / 2, style: .continuous), with: .color(.white.opacity(0.65)))
        }
    }

    /// The capture, aspect-filling the screen, top-aligned, never
    /// mirrored: it's the real interface.
    private func drawCapture(in context: inout GraphicsContext, clip: Path) {
        context.drawLayer { layer in
            layer.clip(to: clip)
            layer.fill(clip, with: .color(Self.emptyScreen))
            guard let capture else { return }
            let size = PixelSize(width: capture.width, height: capture.height)
            let frame = layout.captureFrame(for: size)
            layer.draw(Image(decorative: capture, scale: 1), in: frame)
        }
    }
}
