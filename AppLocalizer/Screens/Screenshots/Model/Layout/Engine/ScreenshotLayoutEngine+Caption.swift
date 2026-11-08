//
//  ScreenshotLayoutEngine+Caption.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// Fitting the caption and placing its lines: uppercase with the locale's
// rules before measuring, an emphasized line measured with the wider of its
// two faces, a box narrowed by the highlight's padding, and a heavy display
// font's fallback set heavy too. Emphasis and highlights are set per line
// after wrapping, so they follow each language's own line breaks. The box
// is reserved at `maxLines`, or sized to the real lines when the headline
// is `tight` or a kicker line sits over it.
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
        /// The kicker's lines and the gap under them; 0 without one.
        var kickerHeight: CGFloat = 0
        var headlineHeight: CGFloat
        /// The subhead's block and the gap above it.
        var subheadHeight: CGFloat
        /// The subhead's block alone: its reserved lines, or its real ones
        /// in a tight box.
        var subheadBlockHeight: CGFloat
        var alignment: LayoutTextAlignment

        /// The whole caption box: kicker, headline and subhead.
        var height: CGFloat { kickerHeight + headlineHeight + subheadHeight }
    }

    struct FittedCaption {
        var headline: CaptionFit
        var subhead: CaptionFit?
        /// The headline's style as set: the template's, at the heavy
        /// fallback weight where a fallback font draws it.
        var headlineStyle: TemplateTextStyle
        var headlineFont: FontChoice
        var subheadFont: FontChoice?
        /// The font the emphasized line is set in.
        var emphasisFont: String?
        var frame: CaptionFrame
        /// The kicker line over the headline, when the template sets one
        /// and the caption has kicker text.
        var kicker: CaptionFit?
        var kickerFont: FontChoice?
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
        var headlineStyle = style.headline
        // A very heavy display face's fallback is set heavy as well, so
        // Arabic or Japanese hold their own next to its Latin caps.
        if headlineFont.isFallback, let weight = catalog.fallbackWeight(for: style.headline.font) { headlineStyle.weight = weight }
        var block = CaptionFitter.Block(text: headlineText, style: headlineStyle, sizeScale: headlineScale, fontName: headlineFont.fontName)
        var emphasisFont: String?
        if let emphasis = headlineStyle.emphasis {
            let font = emphasis.font.flatMap { catalog.covers($0, headlineText) ? $0 : nil } ?? headlineFont.fontName
            emphasisFont = font
            block.alternate = CaptionFitter.Face(
                fontName: font, weight: emphasis.weight ?? headlineStyle.weight, isItalic: emphasis.italic ?? headlineStyle.isItalic
            )
        }
        var headlineBox = box
        if let highlight = headlineStyle.highlight {
            let fullSize = CGFloat(headlineStyle.size * headlineScale) * canvas.unit
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
        var kicker: CaptionFit?
        var kickerFont: FontChoice?
        if let kickerStyle = style.kicker, let text = caption?.visibleKicker {
            let choice = FontChoice.choose(font: kickerStyle.font, for: text, script: script, fonts: template.fonts, catalog: catalog)
            kickerFont = choice
            kicker = fitter.fit(CaptionFitter.Block(text: text, style: kickerStyle, fontName: choice.fontName), in: box, rules: template.fit)
        }
        let unit = canvas.unit
        // A kicker sizes the box to the real lines, like a tight headline,
        // so the device follows the text's height.
        let isTight = style.headline.isTight || style.kicker != nil
        var kickerHeight: CGFloat = 0
        if let kicker {
            let lineHeight: Double = style.kicker?.lineHeight ?? 1.15
            let lines = Double(kicker.lines.count) * kicker.size * lineHeight
            kickerHeight = CGFloat(lines) * unit + CGFloat(Self.kickerGap) * canvas.height
        }
        let reserved = CGFloat(Double(style.headline.maxLines) * style.headline.size * headlineScale * style.headline.lineHeight) * unit
        let headlineHeight = isTight && !headline.lines.isEmpty
            ? CGFloat(Double(headline.lines.count) * headline.size * style.headline.lineHeight) * unit
            : reserved
        let subheadReserved = CGFloat(Double(style.subhead.maxLines) * style.subhead.size * style.subhead.lineHeight) * unit
        var subheadBlockHeight: CGFloat = isHero ? subheadReserved : 0
        if isHero, isTight {
            let lines = subhead?.lines.count ?? 0
            subheadBlockHeight = CGFloat(Double(lines) * (subhead?.size ?? 0) * style.subhead.lineHeight) * unit
        }
        let subheadHeight = subheadBlockHeight > 0 ? subheadBlockHeight + Self.subheadGap * canvas.height : 0
        let frame = CaptionFrame(
            boxX: boxX, boxWidth: boxWidth, kickerHeight: kickerHeight, headlineHeight: headlineHeight, subheadHeight: subheadHeight,
            subheadBlockHeight: subheadBlockHeight, alignment: alignment
        )
        return FittedCaption(
            headline: headline, subhead: subhead, headlineStyle: headlineStyle, headlineFont: headlineFont, subheadFont: subheadFont,
            emphasisFont: emphasisFont, frame: frame, kicker: kicker, kickerFont: kickerFont
        )
    }

    func lines(_ fitted: FittedCaption, box: CGRect, context: Context) -> [LayoutTextLine] {
        let style = context.template.caption
        let headline = LineBlock(
            style: fitted.headlineStyle, font: fitted.headlineFont.fontName, color: TemplateColor(style.ink) ?? .white,
            emphasisFont: fitted.emphasisFont
        )
        let headlineTop = box.minY + fitted.frame.kickerHeight
        var lines = place(
            fitted.headline, block: headline, alignment: fitted.frame.alignment,
            in: CGRect(x: box.minX, y: headlineTop, width: box.width, height: fitted.frame.headlineHeight), context: context
        )
        if let subhead = fitted.subhead, let font = fitted.subheadFont {
            let height = fitted.frame.subheadBlockHeight
            let top = headlineTop + fitted.frame.headlineHeight + fitted.frame.subheadHeight - height
            let block = LineBlock(style: style.subhead, font: font.fontName, color: TemplateColor(style.subInk) ?? .white)
            lines += place(
                subhead, block: block, alignment: fitted.frame.alignment,
                in: CGRect(x: box.minX, y: top, width: box.width, height: height), context: context
            )
        }
        // Last in the list, so the headline's lines stay first.
        if let kicker = fitted.kicker, let font = fitted.kickerFont, let kickerStyle = style.kicker {
            let block = LineBlock(style: kickerStyle, font: font.fontName, color: TemplateColor(style.ink) ?? .white)
            let height = fitted.frame.kickerHeight - CGFloat(Self.kickerGap) * context.canvas.height
            lines += place(
                kicker, block: block, alignment: fitted.frame.alignment,
                in: CGRect(x: box.minX, y: box.minY, width: box.width, height: height), context: context
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

    /// The caption where the template puts it: in a band over the
    /// full-bleed capture (a folded phone, or both, stand under or over
    /// it), or above or below the device.
    func placeCaption(_ frame: CaptionFrame, in result: inout ScreenshotLayout, context: Context, isCover: Bool, pair: PixelSize?) {
        let resolved = context.template
        let width = context.canvas.width
        let height = context.canvas.height
        let safe = resolved.safeArea
        let captionHeight = frame.height
        switch resolved.caption.placement {
        case .band:
            let padding = 0.035 * height
            let bandHeight = captionHeight + 2 * padding
            let atTop = context.isHero || resolved.caption.band.pos == .top
            let bandY = atTop ? 0 : height - bandHeight
            result.band = CGRect(x: 0, y: bandY, width: width, height: bandHeight)
            result.bandColor = TemplateColor(resolved.caption.band.color)
            result.captionBox = CGRect(x: frame.boxX, y: bandY + padding, width: frame.boxWidth, height: captionHeight)
            if isCover || pair != nil {
                // A folded phone (or both) can't fill the canvas: it stands
                // under the band, or over it.
                placeDevice(in: &result, context: context, captionTop: bandY, captionHeight: atTop ? bandHeight : 0, below: !atTop, companion: pair)
            } else {
                result.screen = CGRect(origin: .zero, size: context.canvas.size)
                result.isFullBleed = true
            }
        case .above:
            let top = safe.top * height
            result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: captionHeight)
            placeDevice(in: &result, context: context, captionTop: top, captionHeight: captionHeight, below: false, companion: pair)
        case .below:
            let top = height - max(safe.bottom, Self.belowMinimumBottom) * height - captionHeight
            result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: captionHeight)
            placeDevice(in: &result, context: context, captionTop: top, captionHeight: captionHeight, below: true, companion: pair)
        }
    }
}
