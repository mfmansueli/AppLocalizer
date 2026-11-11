//
//  ScreenshotPainter.swift
//  AppLocalizer
//

import CoreText
import SwiftUI

/// Draws a `ScreenshotLayout` into a SwiftUI graphics context, in canvas
/// pixels: background, the decorations behind, a Two phones slot's phone
/// behind, the capture (in its 3D device frame, tilted when the device has
/// an angle, floating, or full bleed under the band), the band, the
/// decorations in front, then the pre-broken caption lines. Lines are drawn
/// exactly as the layout broke them; nothing re-wraps.
struct ScreenshotPainter {
    let layout: ScreenshotLayout
    let capture: CGImage?
    /// iPhone Duo's cover display beside the inner one, or the capture of
    /// the phone behind, when the layout has a companion.
    var companion: CGImage?

    /// The screen color where there's no capture yet: a switched-off
    /// black screen in every template, so a set still being captured
    /// looks finished (the checks still flag the missing capture).
    static let emptyScreen = Color.black

    func draw(in context: inout GraphicsContext) {
        let canvasRect = CGRect(origin: .zero, size: layout.canvas.size)
        drawBackground(in: &context, rect: canvasRect)
        let decorations = DecorationPainter(layout: layout)
        decorations.draw(front: false, in: &context)
        if let pair = layout.companion, pair.isBehind { drawCompanion(pair, in: &context) }
        if layout.reviews?.showsQuotes == true {
            // A Reviews slot shows no capture.
        } else if layout.isFullBleed {
            drawCapture(capture, in: &context, clip: Path(canvasRect), screen: layout.screen)
        } else if let device = layout.device {
            drawDevice(device, screen: layout.screen, cornerRadius: layout.screenCornerRadius, capture: capture, in: &context)
        } else {
            drawFloatingScreen(in: &context)
        }
        if let pair = layout.companion, !pair.isBehind { drawCompanion(pair, in: &context) }
        // Over the capture when it's full bleed; a folded iPhone Duo stands
        // beside the band instead.
        if let band = layout.band {
            context.fill(Path(band), with: .color(layout.bandColor?.color ?? .black))
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

    /// The second screen: iPhone Duo's folded one, or the phone behind.
    private func drawCompanion(_ pair: LayoutCompanion, in context: inout GraphicsContext) {
        if let device = pair.device {
            drawDevice(device, screen: pair.screen, cornerRadius: pair.screenCornerRadius, capture: companion, in: &context)
        } else {
            drawFloating(pair.screen, cornerRadius: pair.screenCornerRadius, capture: companion, in: &context)
        }
    }

    private func drawDevice(_ device: LayoutDevice, screen rect: CGRect, cornerRadius: CGFloat, capture: CGImage?, in parent: inout GraphicsContext) {
        let frame = DeviceFramePainter(device: device, canvasHeight: layout.canvas.height)
        frame.drawFloor(in: &parent)
        var context = parent
        if let tilt = device.tilt { context.concatenate(tilt.transform) }
        frame.drawBody(in: &context)
        let screen = device.screenPath(rect, cornerRadius: cornerRadius)
        drawCapture(capture, in: &context, clip: screen, screen: rect)
        if let island = device.island {
            context.fill(Path(roundedRect: island, cornerRadius: island.height / 2, style: .continuous), with: .color(.black))
        }
        frame.drawGlare(over: screen, rect: rect, in: &context)
    }

    private func drawFloatingScreen(in context: inout GraphicsContext) {
        let screen = drawFloating(layout.screen, cornerRadius: layout.screenCornerRadius, capture: capture, in: &context)
        if layout.screenRim > 0 {
            context.stroke(screen, with: .color(.white.opacity(0.55)), lineWidth: layout.screenRim)
        }
        if let bar = layout.windowBar {
            context.fill(Path(roundedRect: bar, cornerRadius: bar.height / 2, style: .continuous), with: .color(.white.opacity(0.65)))
        }
    }

    /// A screen floating with a shadow, its capture in it; returns its
    /// outline.
    @discardableResult
    private func drawFloating(_ rect: CGRect, cornerRadius: CGFloat, capture: CGImage?, in context: inout GraphicsContext) -> Path {
        let screen = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
        let height = layout.canvas.height
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.28), radius: height * 0.02, x: 0, y: height * 0.012))
            layer.fill(screen, with: .color(Self.emptyScreen))
        }
        drawCapture(capture, in: &context, clip: screen, screen: rect)
        return screen
    }

    /// The capture, aspect-filling the screen, top-aligned, never
    /// mirrored: it's the real interface. Without one, the screen is
    /// black.
    private func drawCapture(_ capture: CGImage?, in context: inout GraphicsContext, clip: Path, screen: CGRect) {
        let empty = layout.emptyScreen?.color ?? Self.emptyScreen
        context.drawLayer { layer in
            layer.clip(to: clip)
            layer.fill(clip, with: .color(empty))
            guard let capture else { return }
            let size = PixelSize(width: capture.width, height: capture.height)
            let frame = ScreenshotLayout.captureFrame(for: size, in: screen)
            layer.draw(Image(decorative: capture, scale: 1), in: frame)
        }
    }
}
