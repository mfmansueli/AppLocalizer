//
//  ScreenshotLayoutEngine+Reviews.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

// A Reviews slot (`slots[i].layout: quotes`): no device, three real 5-star
// App Store reviews under the headline, centered, each under a drawn rule
// with the reviewer's name. They come from the language's own storefront,
// and from the primary language's where it has fewer than three.
extension ScreenshotLayoutEngine {
    /// The font a review is set in, where it draws the script.
    static let reviewFont = "SF Pro Text"

    /// Places the reviews from `top` down to the canvas's foot and returns
    /// their lines and rules.
    func placeReviews(in layout: inout ScreenshotLayout, context: Context, top: CGFloat, headlineFont: String) {
        let canvas = context.canvas
        let width = canvas.width
        let height = canvas.height
        let quotes = reviews.quotes(for: context.locale)
        layout.reviews = LayoutReviews(
            own: quotes.filter { !$0.isBorrowed }.count, borrowed: quotes.filter(\.isBorrowed).count, isChecked: reviews.isChecked(context.locale),
            signature: quotes.map { $0.text + "\u{1F}" + $0.name }.joined(separator: "\u{1D}")
        )
        layout.device = nil
        layout.screen = .zero
        guard !quotes.isEmpty else { return }
        let landscape = canvas.isLandscape
        let ink = TemplateColor(context.template.caption.ink) ?? .white
        let quoteStyle = TemplateTextStyle(
            font: Self.reviewFont, weight: 400, size: landscape ? 46 : 66, min: 46, lineHeight: 1.22, maxLines: landscape ? 2 : 4
        )
        let nameStyle = TemplateTextStyle(font: headlineFont, weight: 700, size: landscape ? 50 : 70, min: 48, lineHeight: 1.1, maxLines: 1)
        let startY = top + 0.045 * height
        let endY = height - 0.03 * height
        let step = (endY - startY) / CGFloat(quotes.count)
        let boxX = width * 0.08
        let boxWidth = width * 0.84
        let locale = Locale(identifier: context.locale.code)
        let box = CaptionFitter.Box(unit: canvas.unit, width: boxWidth, locale: locale, script: context.script)
        let fitter = CaptionFitter(catalog: catalog)
        let rules = context.template.fit
        // Each review's lines, centered in the caption's ink.
        let line = { (text: String, font: String, weight: Int, size: CGFloat, frame: CGRect) in
            LayoutTextLine(
                text: text, fontName: font, weight: weight, pixelSize: size, frame: frame, alignment: .center, color: ink, tracking: 0,
                isRightToLeft: context.isRightToLeft, isOverflow: false
            )
        }
        for (index, quote) in quotes.enumerated() {
            let rowY = startY + CGFloat(index) * step
            layout.decorations.append(rule(at: CGRect(x: boxX, y: rowY, width: boxWidth, height: 0.012 * height), color: ink))
            let quoteFont = FontChoice.choose(font: Self.reviewFont, for: quote.text, script: context.script, fonts: context.template.fonts, catalog: catalog)
            let quoteFit = fitter.fit(CaptionFitter.Block(text: quote.text, style: quoteStyle, fontName: quoteFont.fontName), in: box, rules: rules)
            let name = context.isRightToLeft ? "\(quote.name) –" : "– \(quote.name)"
            let nameFont = FontChoice.choose(font: headlineFont, for: name, script: context.script, fonts: context.template.fonts, catalog: catalog)
            let nameFit = fitter.fit(CaptionFitter.Block(text: name, style: nameStyle, fontName: nameFont.fontName), in: box, rules: rules)
            let quoteSize = CGFloat(quoteFit.size) * canvas.unit
            let quoteHeight = CGFloat(quoteFit.lines.count) * quoteSize * CGFloat(quoteStyle.lineHeight)
            let nameSize = CGFloat(nameFit.size) * canvas.unit
            let nameHeight = nameSize * CGFloat(nameStyle.lineHeight)
            let textTop = rowY + max(0.02 * height, (step - quoteHeight - nameHeight - 0.012 * height) / 2)
            let quoteLineHeight = quoteSize * CGFloat(quoteStyle.lineHeight)
            for (index, text) in quoteFit.lines.enumerated() {
                let frame = CGRect(x: boxX, y: textTop + CGFloat(index) * quoteLineHeight, width: boxWidth, height: quoteLineHeight)
                layout.lines.append(line(text, quoteFont.fontName, 400, quoteSize, frame))
            }
            if let text = nameFit.lines.first {
                let frame = CGRect(x: boxX, y: textTop + quoteHeight + 0.012 * height, width: boxWidth, height: nameHeight)
                layout.lines.append(line(text, nameFont.fontName, 700, nameSize, frame))
            }
        }
    }

    /// The drawn line above a review, in the caption's ink.
    private func rule(at frame: CGRect, color: TemplateColor) -> LayoutDecoration {
        LayoutDecoration(
            kind: .shape, shape: .rule, art: nil, frame: frame, rotation: 0, isFlipped: false, opacity: 0.85, color: color,
            isFront: false, text: nil, textColor: color, fontName: "", textSize: 0, textWeight: 400, starColor: nil, starSize: 0, starGap: 0
        )
    }
}
