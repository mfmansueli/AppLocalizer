//
//  ArtworkView.swift
//  AppLocalizer
//

import SwiftUI

/// Draws an `ArtworkLayout` at its pixel size: the background, each phone
/// (back first) with its capture, the headline's lines, and the app's
/// icon and name. Scale it down with `.scaleEffect` or a frame for
/// thumbnails; `ArtworkRenderer` renders it for upload.
struct ArtworkView: View {
    /// What it draws: all of it, or one layer of a motion loop's frames.
    enum Layers: Hashable {
        case all
        /// The background and the scene's still parts: nothing, as the
        /// scene moves.
        case background
        /// The phones alone, on clear.
        case phones
        /// The text, the icon and the name, on clear.
        case text
    }

    let layout: ArtworkLayout
    /// Each slot's picked capture in this language.
    let captures: [Int: CGImage]
    var icon: CGImage?
    /// Where in the motion loop, 0–1; a still and the poster are 0.
    var phase: Double = 0
    var layers: Layers = .all

    var body: some View {
        Canvas { context, _ in
            draw(in: &context)
        }
        .frame(width: layout.size.width, height: layout.size.height)
        .overlay(alignment: .topLeading) {
            if layers == .all || layers == .text { iconView }
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext) {
        if layers == .all || layers == .background { drawBackground(in: &context) }
        if layers == .all, let scene = layout.scene {
            context.withCGContext { cgContext in
                // The canvas's y runs down, like the layout's.
                ArtworkScenePainter.draw(scene, in: cgContext, size: layout.size, phase: phase)
            }
        }
        if layers == .all || layers == .phones {
            var phones = context
            if layout.scene?.isMotion == true, layers == .all {
                phones.translateBy(x: 0, y: ArtworkScene.floatOffset(phase, height: layout.size.height))
            }
            for phone in layout.phones {
                draw(phone, in: phones)
            }
        }
        if layers == .all || layers == .text {
            var lines = layout.lines
            if let label = layout.appLabel { lines.append(label.name) }
            CaptionLinePainter(lines: lines, fonts: layout.fonts).draw(in: &context)
        }
    }

    private func drawBackground(in context: inout GraphicsContext) {
        let rect = CGRect(origin: .zero, size: layout.size)
        switch layout.background {
        case let .solid(color):
            context.fill(Path(rect), with: .color(color.color))
        case let .linear(angle, stops):
            let (start, end) = ScreenshotPainter.gradientPoints(angle: angle, in: rect)
            context.fill(Path(rect), with: .linearGradient(Gradient(colors: stops.map(\.color)), startPoint: start, endPoint: end))
        case let .panorama(panorama):
            context.fill(Path(rect), with: .color((panorama.stops.first ?? .black).color))
        }
    }

    private func draw(_ phone: ArtworkPhone, in parent: GraphicsContext) {
        var context = parent
        let center = CGPoint(x: phone.frame.midX, y: phone.frame.midY)
        context.concatenate(
            CGAffineTransform(translationX: center.x, y: center.y).rotated(by: phone.rotation * .pi / 180).translatedBy(x: -center.x, y: -center.y)
        )
        let body = Path(roundedRect: phone.frame, cornerRadius: phone.cornerRadius, style: .continuous)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.3), radius: phone.shadowRadius / 2, x: 0, y: phone.shadowOffset))
            // Without a device, the shadow falls from the screen itself.
            layer.fill(body, with: .color(phone.isBare ? ScreenshotPainter.emptyScreen : phone.color.color))
        }
        let screen = Path(roundedRect: phone.screen, cornerRadius: phone.screenCornerRadius, style: .continuous)
        context.drawLayer { layer in
            layer.clip(to: screen)
            layer.fill(screen, with: .color(ScreenshotPainter.emptyScreen))
            guard let capture = captures[phone.slot] else { return }
            let frame = phone.captureFrame(for: PixelSize(width: capture.width, height: capture.height))
            layer.draw(Image(decorative: capture, scale: 1), in: frame)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let label = layout.appLabel {
            Group {
                if let icon {
                    Image(decorative: icon, scale: 1).resizable().interpolation(.high)
                } else {
                    (layout.lines.first?.color ?? .white).color.opacity(0.25)
                }
            }
            .frame(width: label.iconFrame.width, height: label.iconFrame.height)
            .clipShape(RoundedRectangle(cornerRadius: label.iconFrame.width * 0.225, style: .continuous))
            .offset(x: label.iconFrame.minX, y: label.iconFrame.minY)
        }
    }
}
