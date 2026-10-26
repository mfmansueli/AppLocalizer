//
//  CaptionFitter.swift
//  AppLocalizer
//

import AppKit
import CoreText
import Foundation

/// Fits a caption block into its box (README §4): from the full size down
/// to `min` in 2 u steps (only the full size when shrink is off), the first
/// size where every word fits and the lines don't exceed `maxLines` wins.
/// Otherwise the block overflows and is set at `min`, with the extra lines
/// reported. Measured with Core Text and the locale's line breaking.
struct CaptionFitter {
    var catalog: ScreenshotFontCatalog = .standard

    /// The block to fit, sizes in u.
    struct Block {
        var text: String
        var style: TemplateTextStyle
        /// ×1.06 for the hero headline; `min` isn't scaled.
        var sizeScale: Double = 1
        var fontName: String
    }

    /// Where it goes.
    struct Box {
        /// Pixels per u on this canvas.
        var unit: CGFloat
        /// The box width in pixels.
        var width: CGFloat
        var locale: Locale
        var script: ScreenshotScript
    }

    static let step = 2.0

    func fit(_ block: Block, in box: Box, rules: TemplateFit) -> CaptionFit {
        let fullSize = block.style.size * block.sizeScale
        let minimumSize = min(block.style.min, fullSize)
        var result = CaptionFit(
            text: block.text, lines: [], size: fullSize, fullSize: fullSize, minimumSize: minimumSize,
            maxLines: block.style.maxLines, fits: true, hasWideWord: false, fill: 0
        )
        guard !result.isEmpty else { return result }
        let unbroken = block.text.components(separatedBy: .newlines).joined(separator: " ")
        result.fill = Double(measurer(block, size: fullSize, unit: box.unit).width(of: unbroken) / max(1, CGFloat(block.style.maxLines) * box.width))
        for size in sizes(full: fullSize, minimum: minimumSize, shrink: rules.shrink) {
            let breaks = lines(block, size: size, box: box, hyphenate: rules.hyphenate)
            result.lines = breaks.lines
            result.size = size
            result.hasWideWord = breaks.hasWideWord
            result.fits = !breaks.hasWideWord && breaks.lines.count <= block.style.maxLines
            if result.fits { break }
        }
        return result
    }

    /// The sizes to try, largest first, ending at `minimum`.
    func sizes(full: Double, minimum: Double, shrink: Bool) -> [Double] {
        guard shrink, full > minimum else { return [full] }
        var sizes = Array(stride(from: full, to: minimum, by: -Self.step))
        if let last = sizes.last, last - minimum > 0.001 { sizes.append(minimum) }
        return sizes
    }

    func lines(_ block: Block, size: Double, box: Box, hyphenate: Bool) -> CaptionLineBreaker.LineBreaks {
        let measurer = measurer(block, size: size, unit: box.unit)
        let breaker = CaptionLineBreaker(locale: box.locale, script: box.script, hyphenate: hyphenate, measure: measurer.width(of:))
        return breaker.lines(for: block.text, width: box.width)
    }

    func font(_ block: Block, pixelSize: CGFloat) -> CTFont {
        catalog.font(named: block.fontName, weight: block.style.weight, size: pixelSize)
            ?? NSFont.systemFont(ofSize: pixelSize, weight: ScreenshotFontCatalog.weight(block.style.weight)) as CTFont
    }

    private func measurer(_ block: Block, size: Double, unit: CGFloat) -> CaptionMeasurer {
        let pixelSize = CGFloat(size) * unit
        return CaptionMeasurer(font: font(block, pixelSize: pixelSize), tracking: CGFloat(block.style.tracking ?? 0) * pixelSize)
    }
}
