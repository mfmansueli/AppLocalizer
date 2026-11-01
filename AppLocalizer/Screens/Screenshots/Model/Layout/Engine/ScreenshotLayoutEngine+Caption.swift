//
//  ScreenshotLayoutEngine+Caption.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// Fitting the caption and placing its lines: uppercase with the locale's
// rules before measuring, an emphasized line measured with the wider of its
// two faces, and a box narrowed by the highlight's padding. Emphasis and
// highlights are set per line after wrapping, so they follow each
// language's own line breaks.
extension ScreenshotLayoutEngine {
    /// One caption block's drawing style.
    struct LineBlock {
        var style: TemplateTextStyle
        var font: String
        var color: TemplateColor
        /// The emphasized line's font, when the block has one.
        var emphasisFont: String?
    }

    /// The parts of a layout that place the caption.
    struct CaptionFrame {
        var boxX: CGFloat
        var boxWidth: CGFloat
        var headlineHeight: CGFloat
        var subheadHeight: CGFloat
        var alignment: LayoutTextAlignment
    }

    struct FittedCaption {
        var headline: CaptionFit
        var subhead: CaptionFit?
        var headlineFont: FontChoice
        var subheadFont: FontChoice?
        /// The font the emphasized line is set in.
        var emphasisFont: String?
        var frame: CaptionFrame
    }

    func fitCaption(_ caption: ScreenshotCaption?, context: Context) -> FittedCaption {
        let template = context.template
        let canvas = context.canvas
        let script = context.script
        let isHero = context.isHero
        let style = template.caption
        let width = canvas.width
        let side = template.safeArea.side * width
        let boxWidth = canvas.isLandscape
            ? min(width * 0.62, width - 2 * side)
            : (style.align == .start ? width - 2 * side - width * 0.04 : width - 2 * side)
        let boxX = canvas.isLandscape ? (width - boxWidth) / 2 : (style.align == .start && context.isMirrored ? width - side - boxWidth : side)
        let isCentered = style.align == .center || canvas.display == .visionPro
        let alignment: LayoutTextAlignment = isCentered ? .center : (context.isRightToLeft ? .right : .left)
        let locale = Locale(identifier: context.locale.code)
        let box = CaptionFitter.Box(unit: canvas.unit, width: boxWidth, locale: locale, script: script)
        let fitter = CaptionFitter(catalog: catalog)
        let headlineScale = isHero ? 1.06 : 1
        let rawHeadline = caption?.headline ?? ""
        let headlineText = style.headline.isUppercase ? rawHeadline.uppercased(with: locale) : rawHeadline
        let headlineFont = FontChoice.choose(font: style.headline.font, for: headlineText, script: script, fonts: template.fonts, catalog: catalog)
        var block = CaptionFitter.Block(text: headlineText, style: style.headline, sizeScale: headlineScale, fontName: headlineFont.fontName)
        var emphasisFont: String?
        if let emphasis = style.headline.emphasis {
            let font = emphasis.font.flatMap { catalog.covers($0, headlineText) ? $0 : nil } ?? headlineFont.fontName
            emphasisFont = font
            block.alternate = CaptionFitter.Face(
                fontName: font, weight: emphasis.weight ?? style.headline.weight, isItalic: emphasis.italic ?? style.headline.isItalic
            )
        }
        var headlineBox = box
        if let highlight = style.headline.highlight {
            let fullSize = CGFloat(style.headline.size * headlineScale) * canvas.unit
            headlineBox.width = max(1, boxWidth - fullSize * CGFloat(highlight.horizontalPadding * 2 + 0.08))
        }
        let headline = fitter.fit(block, in: headlineBox, rules: template.fit)
        var subhead: CaptionFit?
        var subheadFont: FontChoice?
        if isHero {
            let text = caption?.visibleSubhead ?? ""
            let choice = FontChoice.choose(font: style.subhead.font, for: text, script: script, fonts: template.fonts, catalog: catalog)
            subheadFont = choice
            subhead = fitter.fit(CaptionFitter.Block(text: text, style: style.subhead, fontName: choice.fontName), in: box, rules: template.fit)
        }
        let unit = canvas.unit
        let headlineHeight = CGFloat(Double(style.headline.maxLines) * style.headline.size * headlineScale * style.headline.lineHeight) * unit
        let subheadHeight = isHero
            ? CGFloat(Double(style.subhead.maxLines) * style.subhead.size * style.subhead.lineHeight) * unit + Self.subheadGap * canvas.height
            : 0
        let frame = CaptionFrame(boxX: boxX, boxWidth: boxWidth, headlineHeight: headlineHeight, subheadHeight: subheadHeight, alignment: alignment)
        return FittedCaption(
            headline: headline, subhead: subhead, headlineFont: headlineFont, subheadFont: subheadFont, emphasisFont: emphasisFont, frame: frame
        )
    }

    func lines(_ fitted: FittedCaption, box: CGRect, context: Context) -> [LayoutTextLine] {
        let style = context.template.caption
        let headline = LineBlock(
            style: style.headline, font: fitted.headlineFont.fontName, color: TemplateColor(style.ink) ?? .white, emphasisFont: fitted.emphasisFont
        )
        var lines = place(
            fitted.headline, block: headline, alignment: fitted.frame.alignment,
            in: CGRect(x: box.minX, y: box.minY, width: box.width, height: fitted.frame.headlineHeight), context: context
        )
        if let subhead = fitted.subhead, let font = fitted.subheadFont {
            let unit = context.canvas.unit
            let height = CGFloat(Double(style.subhead.maxLines) * style.subhead.size * style.subhead.lineHeight) * unit
            let top = box.minY + fitted.frame.headlineHeight + fitted.frame.subheadHeight - height
            let block = LineBlock(style: style.subhead, font: font.fontName, color: TemplateColor(style.subInk) ?? .white)
            lines += place(
                subhead, block: block, alignment: fitted.frame.alignment,
                in: CGRect(x: box.minX, y: top, width: box.width, height: height), context: context
            )
        }
        return lines
    }

    private func place(
        _ fit: CaptionFit, block: LineBlock, alignment: LayoutTextAlignment, in box: CGRect, context: Context
    ) -> [LayoutTextLine] {
        guard !fit.isEmpty else { return [] }
        let style = block.style
        let pixelSize = CGFloat(fit.size) * context.canvas.unit
        let lineHeight = pixelSize * CGFloat(style.lineHeight)
        let top = box.minY + max(0, (box.height - CGFloat(fit.lines.count) * lineHeight) / 2)
        let count = fit.lines.count
        return fit.lines.enumerated().map { index, text in
            var line = LayoutTextLine(
                text: text, fontName: block.font, weight: style.weight, pixelSize: pixelSize,
                frame: CGRect(x: box.minX, y: top + CGFloat(index) * lineHeight, width: box.width, height: lineHeight),
                alignment: alignment, color: block.color, tracking: CGFloat(style.tracking ?? 0) * pixelSize,
                isRightToLeft: context.isRightToLeft, isOverflow: !fit.fits && index >= style.maxLines,
                isItalic: style.isItalic, shadow: style.shadow.flatMap { TemplateShadow($0) }
            )
            if let emphasis = style.emphasis, emphasis.applies(toLine: index, of: count) {
                line.fontName = block.emphasisFont ?? block.font
                line.weight = emphasis.weight ?? style.weight
                line.isItalic = emphasis.italic ?? style.isItalic
                if let color = emphasis.color.flatMap(TemplateColor.init) { line.color = color }
            }
            if let highlight = style.highlight {
                let sign: Double = (index.isMultiple(of: 2) ? 1 : -1) * (context.isMirrored ? -1 : 1)
                line.highlight = LayoutLineHighlight(
                    color: TemplateColor(highlight.color) ?? .white, padding: CGFloat(highlight.horizontalPadding) * pixelSize,
                    rotation: (highlight.rotation ?? 0) * sign, cornerRadius: CGFloat(highlight.radius ?? 0) * pixelSize,
                    shadow: highlight.shadow.flatMap { TemplateShadow($0) }
                )
            }
            return line
        }
    }
}
