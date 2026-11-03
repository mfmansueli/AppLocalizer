//
//  ArtworkScenePainter.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Draws an `ArtworkScene` with Core Graphics at a moment of its loop
/// (`phase`, 0–1; a still is 0): the dusk fade from the top, the glow
/// rising from the bottom, the stars, the moon and two hills. The same
/// drawing makes the still, each frame of the motion loop, and the
/// previews.
enum ArtworkScenePainter {
    static func draw(_ scene: ArtworkScene, in context: CGContext, size: CGSize, phase: Double) {
        let width = size.width
        let height = size.height
        let unit = width / 100
        let drift = CGFloat(ArtworkScene.drift(phase))
        context.saveGState()
        defer { context.restoreGState() }

        // Dusk: a fade from the top.
        let duskOpacity = scene.isMotion ? drift : (scene.isLight ? 0.12 : 0.35)
        if duskOpacity > 0.001, let dusk = gradient([cgColor(12, 10, 46, 0.55 * duskOpacity), cgColor(12, 10, 46, 0)]) {
            context.saveGState()
            context.clip(to: CGRect(origin: .zero, size: size))
            context.drawLinearGradient(dusk, start: .zero, end: CGPoint(x: 0, y: height * 0.75), options: [.drawsAfterEndLocation])
            context.restoreGState()
        }

        // Glow: a soft ellipse rising from the bottom that drifts across.
        let glowColor = scene.isLight ? cgColor(255, 255, 255, 0.7) : cgColor(255, 214, 190, 0.30)
        if let glow = gradient([glowColor, cgColor(255, 255, 255, 0)]) {
            let scale = 1 + 0.08 * (scene.isMotion ? drift : 0)
            let glowWidth = width * 0.8 * scale
            let glowHeight = height * 1.1 * scale
            let shift = scene.isMotion ? (-0.06 + 0.12 * drift) * width * 0.8 : 0
            let center = CGPoint(x: width / 2 + shift, y: height * 0.45 + height * 0.55)
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.scaleBy(x: 1, y: glowHeight / glowWidth)
            context.drawRadialGradient(glow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: glowWidth / 2, options: [])
            context.restoreGState()
        }

        guard scene.hasLandscape else { return }

        // Stars.
        let starColor = scene.isLight ? cgColor(60, 50, 140, 0.55) : cgColor(255, 255, 255, 1)
        for (index, star) in ArtworkScene.starSpots.enumerated() {
            let diameter = max(1, star.size * unit * 0.42)
            let opacity = if scene.isMotion {
                // Twinkles every 5 seconds, each star on its own beat.
                0.18 + 0.77 * (1 - cos(2 * .pi * (phase * ArtworkScene.loopSeconds + Double(index) * 0.7) / 5)) / 2
            } else {
                0.6
            }
            let x = scene.isMirrored ? 100 - star.x : star.x
            context.setFillColor(starColor.copy(alpha: starColor.alpha * opacity) ?? starColor)
            context.fillEllipse(in: CGRect(x: x * width / 100, y: star.y * height / 100, width: diameter, height: diameter))
        }

        // The moon, rising slowly.
        let isSearch = scene.kind == .search
        let moonSize = max(3, (isSearch ? 9 : 4.4) * unit)
        let moonX = (scene.isMirrored ? 22 : (isSearch ? 76 : 72)) * width / 100
        let moonY = (isSearch ? 30 : 26) * height / 100
        let rise = scene.isMotion ? drift : 0
        let moon = CGRect(
            x: moonX + (scene.isMirrored ? 2.4 : -2.4) * moonSize * rise, y: moonY + 0.38 * moonSize * rise,
            width: moonSize, height: moonSize
        )
        context.saveGState()
        context.setShadow(offset: .zero, blur: 3 * unit, color: cgColor(255, 244, 216, 0.55))
        context.setFillColor(cgColor(255, 244, 216, 1))
        context.fillEllipse(in: moon)
        context.restoreGState()

        // Two hills along the bottom.
        let backColor = scene.isLight ? cgColor(80, 70, 170, 0.10) : cgColor(10, 8, 40, 0.20)
        let frontColor = scene.isLight ? cgColor(80, 70, 170, 0.16) : cgColor(10, 8, 40, 0.30)
        let backDrift = scene.isMotion ? (-0.04 + 0.06 * drift) * width * 0.8 : 0
        let frontDrift = scene.isMotion ? -0.05 * width * 0.95 * drift : 0
        let backHeight = height * 0.62
        let frontHeight = height * 0.58
        let back = CGRect(
            x: -0.15 * width + backDrift, y: height + height * (isSearch ? 0.30 : 0.26) - backHeight,
            width: width * 0.8, height: backHeight
        )
        let front = CGRect(
            x: width * 0.25 + frontDrift, y: height + height * (isSearch ? 0.36 : 0.30) - frontHeight,
            width: width * 0.95, height: frontHeight
        )
        for (rect, color) in [(back, backColor), (front, frontColor)] {
            let placed = scene.isMirrored ? CGRect(x: width - rect.maxX, y: rect.minY, width: rect.width, height: rect.height) : rect
            context.setFillColor(color)
            context.fillEllipse(in: placed)
        }
    }

    private static func cgColor(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double) -> CGColor {
        CGColor(srgbRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }

    private static func gradient(_ colors: [CGColor]) -> CGGradient? {
        CGGradient(
            colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
            colors: colors as CFArray,
            locations: nil
        )
    }
}
