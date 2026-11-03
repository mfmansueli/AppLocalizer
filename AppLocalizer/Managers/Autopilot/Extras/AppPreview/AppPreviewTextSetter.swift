//
//  AppPreviewTextSetter.swift
//  AppLocalizer
//

import AppKit
import CoreGraphics
import CoreText
import Foundation

/// Sets a block of text for the App Preview in the template's caption
/// style: fitted with the screenshots' own caption fitter (shrinking to
/// 55 % at most, the locale's line breaking, the script's fallback font)
/// and drawn line by line with Core Text, centered, right to left where
/// the language is. Sizes are pixels.
struct AppPreviewTextSetter {
    var template: ScreenshotTemplate
    var locale: StoreLocale
    var fonts: ScreenshotFontCatalog = .standard

    /// How far a block may shrink, as a share of its size.
    static let shrinkFloor = 0.55

    /// A block fitted and ready to draw.
    struct SetBlock {
        var fit: CaptionFit
        var fontName: String
        var style: TemplateTextStyle
        var color: TemplateColor

        /// One line's height in pixels.
        var lineHeight: CGFloat { CGFloat(fit.size * max(0.8, style.lineHeight)) }

        /// The lines drawn: every line, or `maxLines` when it overflows.
        var drawnLines: [String] { Array(fit.lines.prefix(max(1, fit.maxLines))) }

        /// Pixels the drawn lines take, top to bottom.
        var height: CGFloat { CGFloat(drawnLines.count) * lineHeight }
    }

    /// Fits `text` in the look of `base` at `size` pixels, on at most
    /// `maxLines` lines of `width` pixels.
    func set(_ text: String, like base: TemplateTextStyle, size: CGFloat, maxLines: Int, width: CGFloat, ink: String) -> SetBlock {
        let script = ScreenshotScript(locale: locale)
        let language = Locale(identifier: locale.code)
        let shown = base.isUppercase ? text.uppercased(with: language) : text
        var style = base
        style.size = Double(size)
        style.min = Double(size) * Self.shrinkFloor
        style.maxLines = max(1, maxLines)
        style.shadow = nil
        style.emphasis = nil
        style.highlight = nil
        let fontName = FontChoice.choose(font: base.font, for: shown, script: script, fonts: template.fonts, catalog: fonts).fontName
        let block = CaptionFitter.Block(text: shown, style: style, fontName: fontName)
        let box = CaptionFitter.Box(unit: 1, width: width, locale: language, script: script)
        let fit = CaptionFitter(catalog: fonts).fit(block, in: box, rules: TemplateFit(shrink: true, hyphenate: template.fit.hyphenate))
        return SetBlock(fit: fit, fontName: fontName, style: style, color: TemplateColor(ink) ?? .white)
    }

    /// Draws the block's lines centered across the canvas, the first
    /// line's box starting `top` pixels from the canvas's top edge.
    func draw(_ block: SetBlock, top: CGFloat, in context: CGContext, canvas: CGSize) {
        let pixelSize = CGFloat(block.fit.size)
        let font = fonts.font(named: block.fontName, weight: block.style.weight, size: pixelSize, italic: block.style.isItalic)
            ?? NSFont.systemFont(ofSize: pixelSize, weight: ScreenshotFontCatalog.weight(block.style.weight)) as CTFont
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): Self.cgColor(block.color),
            NSAttributedString.Key(kCTKernAttributeName as String): CGFloat(block.style.tracking ?? 0) * pixelSize,
            NSAttributedString.Key(kCTParagraphStyleAttributeName as String): paragraphStyle(),
        ]
        context.saveGState()
        context.textMatrix = .identity
        for (index, text) in block.drawnLines.enumerated() {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            var leading: CGFloat = 0
            let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading)) - CGFloat(CTLineGetTrailingWhitespaceWidth(line))
            let boxTop = top + CGFloat(index) * block.lineHeight
            let baseline = boxTop + (block.lineHeight - ascent - descent) / 2 + ascent
            context.textPosition = CGPoint(x: (canvas.width - width) / 2, y: canvas.height - baseline)
            CTLineDraw(line, context)
        }
        context.restoreGState()
    }

    /// The writing direction the lines are laid out in.
    private func paragraphStyle() -> CTParagraphStyle {
        let direction: CTWritingDirection = locale.isRTL ? .rightToLeft : .leftToRight
        return withUnsafePointer(to: direction) { pointer in
            var setting = CTParagraphStyleSetting(spec: .baseWritingDirection, valueSize: MemoryLayout<CTWritingDirection>.size, value: pointer)
            return CTParagraphStyleCreate(&setting, 1)
        }
    }

    static func cgColor(_ color: TemplateColor) -> CGColor {
        CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
}
