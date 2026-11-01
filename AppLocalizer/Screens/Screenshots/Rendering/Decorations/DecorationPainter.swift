//
//  DecorationPainter.swift
//  AppLocalizer
//

import CoreText
import SwiftUI

/// Draws a layout's shapes, laurels and badges, the back ones before the
/// device and the front ones after the band. A laurel is eight leaves a
/// side around its value and stars; a badge is its value on a starburst.
struct DecorationPainter {
    let layout: ScreenshotLayout

    func draw(front: Bool, in context: inout GraphicsContext) {
        for decoration in layout.decorations where decoration.isFront == front {
            var layer = context
            layer.opacity = decoration.opacity
            let center = CGPoint(x: decoration.frame.midX, y: decoration.frame.midY)
            layer.concatenate(
                CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: decoration.rotation * .pi / 180)
                    .translatedBy(x: -center.x, y: -center.y)
            )
            switch decoration.kind {
            case .shape:
                var shapeLayer = layer
                if decoration.isFlipped {
                    shapeLayer.concatenate(CGAffineTransform(translationX: center.x, y: 0).scaledBy(x: -1, y: 1).translatedBy(x: -center.x, y: 0))
                }
                let outline = DecorationShapePath.path(for: decoration.shape ?? .blob)
                shapeLayer.fill(DecorationShapePath.fitted(outline, in: decoration.frame), with: .color(decoration.color.color))
            case .badge:
                layer.fill(DecorationShapePath.fitted(DecorationShapePath.burst, in: decoration.frame), with: .color(decoration.color.color))
                drawText(decoration, in: &layer)
            case .laurel:
                drawLeaves(decoration, in: &layer)
                drawText(decoration, in: &layer)
            }
        }
    }

    /// Eight leaves on each side, from the bottom up, each a little smaller.
    private func drawLeaves(_ decoration: LayoutDecoration, in context: inout GraphicsContext) {
        let frame = decoration.frame
        let side = min(frame.width, frame.height)
        let radius = side * 0.42
        let center = CGPoint(x: frame.width / 2, y: frame.height * 0.5)
        for index in 0..<8 {
            let angle = (222 - Double(index) * 15) * .pi / 180
            let scale = 1 - Double(index) * 0.045
            let leafSize = CGSize(width: radius * 0.38 * scale, height: radius * 0.16 * scale)
            let x = center.x + radius * cos(angle)
            let y = center.y - radius * sin(angle) * 0.95
            let rotation = -(angle * 180 / .pi - 90) + 38
            leaf(at: CGPoint(x: frame.minX + x, y: frame.minY + y), size: leafSize, rotation: rotation, color: decoration.color, in: &context)
            leaf(at: CGPoint(x: frame.minX + frame.width - x, y: frame.minY + y), size: leafSize, rotation: -rotation, color: decoration.color, in: &context)
        }
    }

    private func leaf(at center: CGPoint, size: CGSize, rotation: Double, color: TemplateColor, in context: inout GraphicsContext) {
        var layer = context
        layer.concatenate(CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rotation * .pi / 180))
        layer.fill(Path(ellipseIn: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)), with: .color(color.color))
    }

    /// The value, and a laurel's stars under it, centered as one column.
    private func drawText(_ decoration: LayoutDecoration, in context: inout GraphicsContext) {
        guard let text = decoration.text, !text.isEmpty else { return }
        let frame = decoration.frame
        let font = layout.fonts.font(named: decoration.fontName, weight: decoration.textWeight, size: decoration.textSize)
            ?? NSFont.systemFont(ofSize: decoration.textSize, weight: ScreenshotFontCatalog.weight(decoration.textWeight)) as CTFont
        let value = Text(verbatim: text).font(Font(font)).foregroundStyle(decoration.textColor.color)
        guard let starColor = decoration.starColor, decoration.starSize > 0 else {
            context.draw(value, at: CGPoint(x: frame.midX, y: frame.midY), anchor: .center)
            return
        }
        let columnHeight = decoration.textSize + decoration.starGap + decoration.starSize
        let top = frame.midY - columnHeight / 2
        context.draw(value, at: CGPoint(x: frame.midX, y: top + decoration.textSize / 2), anchor: .center)
        let stars = Text(verbatim: "★★★★★")
            .font(.system(size: decoration.starSize))
            .tracking(decoration.starSize * 0.06)
            .foregroundStyle(starColor.color)
        context.draw(stars, at: CGPoint(x: frame.midX, y: top + decoration.textSize + decoration.starGap + decoration.starSize / 2), anchor: .center)
    }
}
