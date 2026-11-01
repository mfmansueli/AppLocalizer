//
//  ScreenshotLayoutEngine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Lays out one render: the template resolved for the slot, the caption
/// fitted with the locale's fonts and line breaking, the caption box
/// reserved at its full height so the device never moves between locales,
/// then the device (or the full-bleed capture) below it. Mirrors the
/// layout in right-to-left locales when `rtl.mirror` is on.
struct ScreenshotLayoutEngine {
    var catalog: ScreenshotFontCatalog = .standard

    /// The space between headline and subhead, as a fraction of the canvas
    /// height.
    static let subheadGap = 0.012

    /// What every step of one layout needs.
    private struct Context {
        var template: ScreenshotTemplate
        var slot: Int
        var canvas: ScreenshotCanvas
        var locale: StoreLocale
        var script: ScreenshotScript
        var isRightToLeft: Bool
        var isMirrored: Bool
        var isHero: Bool
    }

    /// One caption block's drawing style.
    private struct LineBlock {
        var style: TemplateTextStyle
        var font: String
        var color: TemplateColor
    }

    /// The parts of a layout that place the caption.
    private struct CaptionFrame {
        var boxX: CGFloat
        var boxWidth: CGFloat
        var headlineHeight: CGFloat
        var subheadHeight: CGFloat
        var alignment: LayoutTextAlignment
    }

    func layout(
        _ template: ScreenshotTemplate,
        slot: Int,
        locale: StoreLocale,
        displayType: ScreenshotDisplayType,
        caption: ScreenshotCaption?,
        captureSize: PixelSize? = nil
    ) -> ScreenshotLayout {
        let resolved = template.resolved(forSlot: slot)
        let canvas = ScreenshotCanvas(display: displayType, orientation: resolved.canvas.orientation(for: displayType))
        let script = ScreenshotScript(locale: locale)
        let isRightToLeft = locale.isRTL || script.isRightToLeft
        let isMirrored = isRightToLeft && resolved.rightToLeft.mirror
        let isHero = template.isHero(slot: slot)
        let context = Context(
            template: resolved, slot: slot, canvas: canvas, locale: locale, script: script,
            isRightToLeft: isRightToLeft, isMirrored: isMirrored, isHero: isHero
        )
        let fitted = fitCaption(caption, context: context)

        let width = canvas.width
        let height = canvas.height
        let safe = resolved.safeArea
        var result = ScreenshotLayout(
            canvas: canvas, locale: locale.code, isRightToLeft: isRightToLeft, isMirrored: isMirrored,
            background: LayoutBackground(resolved.background, slot: slot, slotCount: template.slots.count, isMirrored: isMirrored),
            band: nil, bandColor: nil, captionBox: .zero,
            safeArea: CGRect(x: safe.side * width, y: safe.top * height, width: width * (1 - 2 * safe.side), height: height * (1 - safe.top - safe.bottom)),
            lines: [], device: nil, screen: .zero, screenCornerRadius: 0, screenHasShadow: false, isFullBleed: false,
            headline: fitted.headline, subhead: fitted.subhead, headlineFont: fitted.headlineFont, subheadFont: fitted.subheadFont,
            fonts: catalog
        )
        let frame = fitted.frame
        let captionHeight = frame.headlineHeight + frame.subheadHeight
        if displayType == .watch {
            result.captionBox = .zero
            result.screen = CGRect(origin: .zero, size: canvas.size)
            result.isFullBleed = true
            return result
        }
        if displayType == .visionPro {
            let top = 0.07 * height
            result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: captionHeight)
            let aspect = captureSize.flatMap { $0.width > 0 ? CGFloat($0.height) / CGFloat($0.width) : nil } ?? 0.75
            placeWindow(in: &result, top: top + captionHeight + 0.05 * height, hasCaption: captionHeight > 0, aspect: min(max(aspect, 0.5625), 1.25))
            result.lines = lines(fitted, box: result.captionBox, context: context)
            return result
        }
        if resolved.caption.placement == .band {
            let padding = 0.035 * height
            let bandHeight = captionHeight + 2 * padding
            let atTop = isHero || resolved.caption.band.pos == .top
            let bandY = atTop ? 0 : height - bandHeight
            result.band = CGRect(x: 0, y: bandY, width: width, height: bandHeight)
            result.bandColor = TemplateColor(resolved.caption.band.color)
            result.captionBox = CGRect(x: frame.boxX, y: bandY + padding, width: frame.boxWidth, height: captionHeight)
            result.screen = CGRect(origin: .zero, size: canvas.size)
            result.isFullBleed = true
        } else {
            let top = safe.top * height
            result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: captionHeight)
            let deviceTop = top + captionHeight + resolved.caption.gap * height
            placeDevice(in: &result, context: context, top: deviceTop)
        }
        result.lines = lines(fitted, box: result.captionBox, context: context)
        return result
    }

    // MARK: - Caption

    private struct FittedCaption {
        var headline: CaptionFit
        var subhead: CaptionFit?
        var headlineFont: FontChoice
        var subheadFont: FontChoice?
        var frame: CaptionFrame
    }

    private func fitCaption(_ caption: ScreenshotCaption?, context: Context) -> FittedCaption {
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
        let box = CaptionFitter.Box(unit: canvas.unit, width: boxWidth, locale: Locale(identifier: context.locale.code), script: script)
        let fitter = CaptionFitter(catalog: catalog)
        let headlineScale = isHero ? 1.06 : 1
        let headlineText = caption?.headline ?? ""
        let headlineFont = FontChoice.choose(font: style.headline.font, for: headlineText, script: script, fonts: template.fonts, catalog: catalog)
        let headline = fitter.fit(
            CaptionFitter.Block(text: headlineText, style: style.headline, sizeScale: headlineScale, fontName: headlineFont.fontName),
            in: box, rules: template.fit
        )
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
            headline: headline, subhead: subhead, headlineFont: headlineFont, subheadFont: subheadFont, frame: frame
        )
    }

    private func lines(_ fitted: FittedCaption, box: CGRect, context: Context) -> [LayoutTextLine] {
        let style = context.template.caption
        let headline = LineBlock(style: style.headline, font: fitted.headlineFont.fontName, color: TemplateColor(style.ink) ?? .white)
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
        return fit.lines.enumerated().map { index, text in
            LayoutTextLine(
                text: text, fontName: block.font, weight: style.weight, pixelSize: pixelSize,
                frame: CGRect(x: box.minX, y: top + CGFloat(index) * lineHeight, width: box.width, height: lineHeight),
                alignment: alignment, color: block.color, tracking: CGFloat(style.tracking ?? 0) * pixelSize,
                isRightToLeft: context.isRightToLeft, isOverflow: !fit.fits && index >= style.maxLines
            )
        }
    }

    // MARK: - Window

    /// Apple Vision Pro: the capture in a floating window of its own shape
    /// (height ÷ width), with a light rim, centered under the caption, and
    /// the window bar below it.
    private func placeWindow(in layout: inout ScreenshotLayout, top: CGFloat, hasCaption: Bool, aspect: CGFloat) {
        let width = layout.canvas.width
        let height = layout.canvas.height
        let barHeight = max(2, (0.011 * width).rounded())
        let barBottom = 0.045 * height
        let available = height - barBottom - barHeight - 0.03 * height - top
        var windowWidth = width * (hasCaption ? 0.5 : 0.6)
        var windowHeight = windowWidth * aspect
        if windowHeight > available {
            windowHeight = max(0, available)
            windowWidth = windowHeight / aspect
        }
        let y = hasCaption ? top : (height - windowHeight) / 2 - 0.03 * height
        let window = CGRect(x: (width - windowWidth) / 2, y: y, width: windowWidth, height: windowHeight)
        layout.screen = window
        layout.screenCornerRadius = max(3, 0.025 * width)
        layout.screenHasShadow = true
        layout.screenRim = max(1, (0.004 * width).rounded())
        layout.windowBar = CGRect(x: (width - 0.16 * width) / 2, y: height - barBottom - barHeight, width: 0.16 * width, height: barHeight)
    }

    // MARK: - Device

    private func placeDevice(in layout: inout ScreenshotLayout, context: Context, top: CGFloat) {
        let template = context.template
        let canvas = layout.canvas
        let width = canvas.width
        let height = canvas.height
        guard template.device.show else {
            let side = template.safeArea.side * width
            layout.screen = CGRect(x: side, y: top, width: width - 2 * side, height: height - top)
            layout.screenCornerRadius = 0.05 * width
            layout.screenHasShadow = true
            return
        }
        let shape = Self.deviceShape(for: canvas.display)
        let screenAspect = height / width
        let bezelRatio = shape.bezel
        var deviceWidth = template.device.width * width * (context.isHero ? 0.96 : 1)
        var deviceHeight = deviceWidth * (1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio * deviceWidth
        let maximumHeight = height * (1 + template.device.bleed) - top
        if canvas.isLandscape, deviceHeight > maximumHeight {
            deviceWidth = maximumHeight / ((1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio)
            deviceHeight = maximumHeight
        }
        var offset = template.device.offset * width * (context.slot.isMultiple(of: 2) ? 1 : -1)
        if layout.isMirrored { offset = -offset }
        let bezel = bezelRatio * deviceWidth
        let frame = CGRect(x: (width - deviceWidth) / 2 + offset, y: top, width: deviceWidth, height: deviceHeight)
        let screen = frame.insetBy(dx: bezel, dy: bezel)
        let island = shape.hasIsland ? CGRect(
            x: screen.midX - screen.width * 0.15, y: screen.minY + screen.width * 0.03,
            width: screen.width * 0.3, height: screen.width * 0.085
        ) : nil
        layout.device = LayoutDevice(
            frame: frame, cornerRadius: deviceWidth * shape.corner, bezel: bezel,
            color: TemplateColor(template.device.color) ?? .black, island: island,
            shadowOffset: height * 0.012, shadowRadius: height * 0.04
        )
        layout.screen = screen
        layout.screenCornerRadius = deviceWidth * shape.screenCorner
    }

    /// The frame drawn around the capture, as fractions of the device's
    /// width: an iPhone's thin bezel, round corners and Dynamic Island; an
    /// iPad's squarer corners; iPhone Duo unfolded between the two, with
    /// no island on its inner display.
    static func deviceShape(for display: ScreenshotDisplayType) -> DeviceShape {
        switch display {
        case .iPad: DeviceShape(bezel: 0.028, corner: 0.05, screenCorner: 0.035, hasIsland: false)
        case .iPhoneDuo: DeviceShape(bezel: 0.03, corner: 0.075, screenCorner: 0.055, hasIsland: false)
        default: DeviceShape(bezel: 0.034, corner: 0.15, screenCorner: 0.125, hasIsland: true)
        }
    }

    /// A device frame's bezel and corner radii, as fractions of its width,
    /// and whether its screen has a Dynamic Island.
    struct DeviceShape: Equatable {
        let bezel: CGFloat
        let corner: CGFloat
        let screenCorner: CGFloat
        let hasIsland: Bool
    }
}
