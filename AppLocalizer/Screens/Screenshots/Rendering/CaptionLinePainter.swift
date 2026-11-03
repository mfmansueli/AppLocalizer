//
//  CaptionLinePainter.swift
//  AppLocalizer
//

import CoreText
import SwiftUI

/// Draws the pre-broken caption lines: each in its own face (an emphasized
/// line may differ), slanted where italic, with its text shadow and, with
/// a highlight, on a marker bar as wide as its text plus the padding,
/// turned about the bar's center with the text on it.
struct CaptionLinePainter {
    let lines: [LayoutTextLine]
    let fonts: ScreenshotFontCatalog

    init(layout: ScreenshotLayout) {
        self.init(lines: layout.lines, fonts: layout.fonts)
    }

    /// Lines laid out elsewhere: the header and search artwork's.
    init(lines: [LayoutTextLine], fonts: ScreenshotFontCatalog) {
        self.lines = lines
        self.fonts = fonts
    }

    func draw(in context: inout GraphicsContext) {
        for line in lines {
            let font = fonts.font(named: line.fontName, weight: line.weight, size: line.pixelSize, italic: line.isItalic)
                ?? NSFont.systemFont(ofSize: line.pixelSize, weight: ScreenshotFontCatalog.weight(line.weight)) as CTFont
            let text = Text(verbatim: line.text)
                .font(Font(font))
                .tracking(line.tracking)
                .foregroundStyle(line.color.color.opacity(line.isOverflow ? 0.55 : 1))
            if let highlight = line.highlight {
                drawHighlighted(text, line: line, font: font, highlight: highlight, in: &context)
            } else {
                let (point, anchor) = Self.position(of: line, frame: line.frame)
                drawText(text, at: point, anchor: anchor, shadow: line.shadow, size: line.pixelSize, in: &context)
            }
        }
    }

    private func drawHighlighted(_ text: Text, line: LayoutTextLine, font: CTFont, highlight: LayoutLineHighlight, in context: inout GraphicsContext) {
        let textWidth = CaptionMeasurer.width(of: line.text, font: font, tracking: line.tracking)
        let barWidth = textWidth + 2 * highlight.padding
        let frame = line.frame
        let barX = switch line.alignment {
        case .left: frame.minX
        case .center: frame.midX - barWidth / 2
        case .right: frame.maxX - barWidth
        }
        let bar = CGRect(x: barX, y: frame.minY, width: barWidth, height: frame.height)
        var layer = context
        layer.concatenate(
            CGAffineTransform(translationX: bar.midX, y: bar.midY).rotated(by: highlight.rotation * .pi / 180).translatedBy(x: -bar.midX, y: -bar.midY)
        )
        let shape = Path(roundedRect: bar, cornerRadius: highlight.cornerRadius, style: .continuous)
        if let shadow = highlight.shadow {
            layer.drawLayer { shadowLayer in
                shadowLayer.addFilter(.blur(radius: shadow.blur * line.pixelSize / 2))
                shadowLayer.fill(shape.offsetBy(dx: shadow.x * line.pixelSize, dy: shadow.y * line.pixelSize), with: .color(shadow.color.color))
            }
        }
        layer.fill(shape, with: .color(highlight.color.color))
        drawText(text, at: CGPoint(x: bar.midX, y: bar.midY), anchor: .center, shadow: line.shadow, size: line.pixelSize, in: &layer)
    }

    private func drawText(_ text: Text, at point: CGPoint, anchor: UnitPoint, shadow: TemplateShadow?, size: CGFloat, in context: inout GraphicsContext) {
        guard let shadow else {
            context.draw(text, at: point, anchor: anchor)
            return
        }
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: shadow.color.color, radius: shadow.blur * size / 2, x: shadow.x * size, y: shadow.y * size))
            layer.draw(text, at: point, anchor: anchor)
        }
    }

    private static func position(of line: LayoutTextLine, frame: CGRect) -> (CGPoint, UnitPoint) {
        switch line.alignment {
        case .left: (CGPoint(x: frame.minX, y: frame.midY), .leading)
        case .center: (CGPoint(x: frame.midX, y: frame.midY), .center)
        case .right: (CGPoint(x: frame.maxX, y: frame.midY), .trailing)
        }
    }
}
