//
//  ArtworkLayoutEngine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Lays out the product page header (21:9), the search results image
/// (3:2) or the one 16:9 image for both, from a direction's template: its
/// background, headline style and device color.
///
/// - The header is the brand first: the app's icon and name, centered at
///   36% of the height, with its short line under them, and no phone; on
///   iPhone only the middle shows and the status bar, Back and Share sit
///   over the top.
/// - The 16:9 image puts the same at 16%, then the search artwork's phone,
///   floating screen or nothing in the middle, running off the bottom.
/// - Search results says what the app does at a glance: the headline on
///   one side and a phone with a real capture (or the screen without a
///   device, or a scene) on the other, with the app's icon and name at the
///   bottom.
///
/// Distances are hundredths of the width, as the design canvas draws them.
/// The headline shrinks until every word fits its column and the lines its
/// room. Right-to-left languages mirror the layout; the captures never are.
struct ArtworkLayoutEngine {
    var catalog: ScreenshotFontCatalog = .standard

    /// The smallest the headline gets, as a share of its full size.
    static let smallestScale = 0.4

    /// The bezel on each side, as a share of the screen's width.
    private static let bezel = 0.035

    /// - Parameters:
    ///   - slots: The slots whose captures the phones show, front first;
    ///     only the first shows.
    ///   - captureSizes: Each slot's capture size, for the phone's shape.
    ///   - shows: What the search artwork (and the 16:9 image) shows.
    ///   - isMotion: It's a motion loop: the light moves over it.
    func layout(
        _ template: ScreenshotTemplate, kind: AutopilotArtworkKind, locale: StoreLocale, headline: String,
        slots: [Int], captureSizes: [Int: PixelSize] = [:], appName: String? = nil,
        shows: AutopilotArtworkShow = .phone, isMotion: Bool = false
    ) -> ArtworkLayout {
        let size = kind.pixelSize.cgSize
        let unit = size.width / 100
        let script = ScreenshotScript(locale: locale)
        let isRightToLeft = locale.isRTL || script.isRightToLeft
        let isMirrored = isRightToLeft && template.rightToLeft.mirror
        let job = Job(
            template: template, locale: locale, headline: headline, name: appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            slots: slots, captureSizes: captureSizes, shows: shows,
            size: size, unit: unit, isRightToLeft: isRightToLeft, isMirrored: isMirrored
        )
        let parts = switch kind {
        case .header, .wide: centered(kind: kind, job)
        case .search: search(job)
        }
        let background = background(template, isMirrored: isMirrored)
        let scene: ArtworkScene? = shows == .scene || isMotion
            ? ArtworkScene(
                kind: kind, hasLandscape: shows == .scene, isMotion: isMotion,
                isLight: Self.isLight(background, ink: template.caption.ink), isMirrored: isMirrored
            )
            : nil
        return ArtworkLayout(
            kind: kind, locale: locale.code, isMirrored: isMirrored, background: background,
            panorama: shows == .scene ? nil : Self.panorama(template, size: size, isMirrored: isMirrored),
            safeArea: ArtworkSafeArea.rect(for: kind), headlineBox: parts.headlineBox, lines: parts.lines, headline: parts.fit,
            phones: parts.phones, appLabel: parts.label, fonts: catalog, scene: scene
        )
    }

    /// What's laid out: the template, the words and the captures, and the
    /// artwork's size, its unit (a hundredth of its width) and which way it
    /// reads.
    private struct Job {
        var template: ScreenshotTemplate
        var locale: StoreLocale
        var headline: String
        var name: String
        var slots: [Int]
        var captureSizes: [Int: PixelSize]
        var shows: AutopilotArtworkShow
        var size: CGSize
        var unit: CGFloat
        var isRightToLeft: Bool
        var isMirrored: Bool

        /// `x` from the leading edge, mirrored for right-to-left.
        func place(_ x: CGFloat, _ width: CGFloat) -> CGFloat {
            isMirrored ? size.width - x - width : x
        }
    }

    /// Where a phone goes: `width` is its screen's, at (`x`, `y`) from the
    /// leading top corner before mirroring; without a device (`isBare`) it's
    /// the screen alone, cut at `clipHeight`.
    private struct PhoneSpot {
        var slot: Int
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var rotation: Double
        var isBare: Bool
        var clipHeight: CGFloat?
    }

    /// What a kind's layout draws besides the background.
    private struct Parts {
        var fit: CaptionFit
        var lines: [LayoutTextLine]
        var headlineBox: CGRect
        var phones: [ArtworkPhone]
        var label: ArtworkAppLabel?
    }

    // MARK: - Header and 16:9

    /// The icon and name centered (at 36% of the height, or 16% on the
    /// 16:9 image), the line under them, and on the 16:9 image the phone or
    /// floating screen in the middle.
    private func centered(kind: AutopilotArtworkKind, _ job: Job) -> Parts {
        let (template, locale, name) = (job.template, job.locale, job.name)
        let unit = job.unit
        let size = job.size
        let top = size.height * (kind == .wide ? 0.16 : 0.36)
        let ink = TemplateColor(template.caption.ink) ?? .white
        // The wordmark: the icon and the name, side by side.
        let iconSize = 7 * unit
        let gap = 1.6 * unit
        let nameSize = 7.4 * unit
        let nameFont = fontName(for: name, template: template, locale: locale)
        let nameWidth = name.isEmpty ? 0 : measure(name, fontName: nameFont, weight: 700, italic: false, size: nameSize, tracking: nameSize * 0.01)
        let rowWidth = iconSize + gap + nameWidth
        let rowX = (size.width - rowWidth) / 2
        let label = name.isEmpty ? nil : ArtworkAppLabel(
            iconFrame: CGRect(x: job.place(rowX, iconSize), y: top, width: iconSize, height: iconSize),
            name: LayoutTextLine(
                text: name, fontName: nameFont, weight: 700, pixelSize: nameSize,
                frame: CGRect(x: job.place(rowX + iconSize + gap, nameWidth), y: top, width: nameWidth, height: iconSize),
                alignment: .center, color: ink, tracking: nameSize * 0.01, isRightToLeft: job.isRightToLeft, isOverflow: false
            )
        )
        // The line under it: at most two lines, 48 wide.
        let lineTop = top + (label == nil ? 0 : iconSize + gap)
        let columnWidth = 48 * unit
        let fullSize = 2.7 * unit
        var fitted = fitHeadline(
            job.headline, template: template, locale: locale, fullSize: fullSize,
            box: CGRect(x: 0, y: 0, width: columnWidth, height: fullSize * 1.2 * 2 + 1), maxLines: 2
        )
        fitted.style.weight = 500
        let lineHeight = CGFloat(fitted.fit.size * 1.2)
        let placement = TextPlacement(
            x: (size.width - columnWidth) / 2, top: lineTop, width: columnWidth, lineHeight: lineHeight,
            alignment: .center, isRightToLeft: job.isRightToLeft, isMirrored: job.isMirrored
        )
        let lines = lines(fitted, template: template, placement: placement, place: job.place)
        let textHeight = lineHeight * CGFloat(fitted.fit.lines.count)
        var phones: [ArtworkPhone] = []
        if kind == .wide, job.shows != .scene, let slot = job.slots.first {
            let isBare = job.shows == .ui
            let width = (isBare ? 30 : 21) * unit
            let bezel = isBare ? 0 : max(1, (width * Self.bezel).rounded())
            phones.append(phone(PhoneSpot(
                slot: slot, x: (size.width - width - 2 * bezel) / 2, y: size.height * (isBare ? 0.56 : 0.5), width: width,
                rotation: 0, isBare: isBare, clipHeight: isBare ? size.height * 0.4 : nil
            ), job))
        }
        let headlineBox = fitted.fit.isEmpty
            ? CGRect.zero
            : CGRect(x: job.place(placement.x, columnWidth), y: lineTop, width: columnWidth, height: textHeight)
        return Parts(fit: fitted.fit, lines: lines, headlineBox: headlineBox, phones: phones, label: label)
    }

    // MARK: - Search results

    /// The headline on the leading side, the phone (or the screen without
    /// a device) turned on the other, or for a scene a bigger headline and
    /// no app; the icon and name at the bottom.
    private func search(_ job: Job) -> Parts {
        let (template, locale, name) = (job.template, job.locale, job.name)
        let unit = job.unit
        let size = job.size
        let isScene = job.shows == .scene
        let left = 7 * unit
        let top = (isScene ? 14 : 9) * unit
        let columnWidth = (isScene ? 56 : 46) * unit
        let fullSize = (isScene ? 8 : 6.6) * unit
        let fitted = fitHeadline(
            job.headline, template: template, locale: locale, fullSize: fullSize,
            box: CGRect(x: 0, y: 0, width: columnWidth, height: max(1, size.height * 0.62 - top)), maxLines: 4
        )
        let lineHeight = CGFloat(fitted.fit.size * fitted.style.lineHeight)
        let placement = TextPlacement(
            x: left, top: top, width: columnWidth, lineHeight: lineHeight,
            alignment: job.isRightToLeft ? .right : .left, isRightToLeft: job.isRightToLeft, isMirrored: job.isMirrored
        )
        let lines = lines(fitted, template: template, placement: placement, place: job.place)
        let textHeight = lineHeight * CGFloat(fitted.fit.lines.count)
        // The app's icon and name at the bottom.
        var label: ArtworkAppLabel?
        if !name.isEmpty {
            let iconSize = 5.4 * unit
            let gap = 1.2 * unit
            let nameSize = 3 * unit
            let nameFont = fontName(for: name, template: template, locale: locale)
            let nameWidth = measure(name, fontName: nameFont, weight: 600, italic: false, size: nameSize, tracking: 0)
            let y = size.height * 0.9 - iconSize
            label = ArtworkAppLabel(
                iconFrame: CGRect(x: job.place(left, iconSize), y: y, width: iconSize, height: iconSize),
                name: LayoutTextLine(
                    text: name, fontName: nameFont, weight: 600, pixelSize: nameSize,
                    frame: CGRect(x: job.place(left + iconSize + gap, nameWidth), y: y, width: nameWidth, height: iconSize),
                    alignment: job.isRightToLeft ? .right : .left, color: TemplateColor(template.caption.ink) ?? .white,
                    tracking: 0, isRightToLeft: job.isRightToLeft, isOverflow: false
                )
            )
        }
        var phones: [ArtworkPhone] = []
        if !isScene, let slot = job.slots.first {
            let spot = job.shows == .ui
                ? PhoneSpot(slot: slot, x: 55 * unit, y: 11 * unit, width: 36 * unit, rotation: -4, isBare: true, clipHeight: 50 * unit)
                : PhoneSpot(slot: slot, x: 57 * unit, y: 13 * unit, width: 30 * unit, rotation: -6, isBare: false, clipHeight: nil)
            phones.append(phone(spot, job))
        }
        let headlineBox = fitted.fit.isEmpty ? CGRect.zero : CGRect(x: job.place(left, columnWidth), y: top, width: columnWidth, height: textHeight)
        return Parts(fit: fitted.fit, lines: lines, headlineBox: headlineBox, phones: phones, label: label)
    }

    // MARK: - Background and phones

    /// The template's background over the whole image; a panorama becomes
    /// its gradient across it.
    private func background(_ template: ScreenshotTemplate, isMirrored: Bool) -> LayoutBackground {
        let background = LayoutBackground(template.background, slot: 0, slotCount: 1, isMirrored: isMirrored)
        guard case let .panorama(panorama) = background else { return background }
        return panorama.stops.count > 1 ? .linear(angle: isMirrored ? 270 : 90, stops: panorama.stops) : .solid(panorama.stops[0])
    }

    /// A panorama look's picture across the artwork, in slots of about a
    /// portrait iPhone screenshot's shape: 5 on the header, 3 on search
    /// results, 4 on the 16:9 image. Nil for other looks.
    static func panorama(_ template: ScreenshotTemplate, size: CGSize, isMirrored: Bool) -> LayoutPanorama? {
        guard template.background.kind == .panorama else { return nil }
        let stops = template.background.stops.compactMap { TemplateColor($0) }
        guard stops.count > 1 else { return nil }
        let portrait = ScreenshotDisplayType.iPhone.portraitPixelSize
        let slotWidth = size.height * CGFloat(portrait.width) / CGFloat(portrait.height)
        let slots = max(1, Int((size.width / slotWidth).rounded()))
        return LayoutPanorama(stops: stops, slotCount: slots, slot: 0, isMirrored: isMirrored)
    }

    /// A light background with dark text: the scene's stars and hills go
    /// dark, its glow white.
    static func isLight(_ background: LayoutBackground, ink: String) -> Bool {
        let first: TemplateColor? = switch background {
        case let .solid(color): color
        case let .linear(_, stops): stops.first
        case let .panorama(panorama): panorama.stops.first
        }
        guard let first else { return false }
        let inkIsWhite = (TemplateColor(ink).map { ArtworkContrast.luminance($0) > 0.9 }) ?? false
        return ArtworkContrast.luminance(first) > 0.45 && !inkIsWhite
    }

    /// One phone at `spot`; without a device it's the screen alone,
    /// rounded.
    private func phone(_ spot: PhoneSpot, _ job: Job) -> ArtworkPhone {
        let (width, isBare) = (spot.width, spot.isBare)
        let aspect = job.captureSizes[spot.slot].map { CGFloat($0.height) / CGFloat(max(1, $0.width)) } ?? 2.17
        let bezel = isBare ? 0 : max(1, (width * Self.bezel).rounded())
        let screenHeight = spot.clipHeight ?? width * aspect
        let body = CGRect(x: spot.x, y: spot.y, width: width + 2 * bezel, height: screenHeight + 2 * bezel)
        let placed = CGRect(x: job.place(body.minX, body.width), y: body.minY, width: body.width, height: body.height)
        return ArtworkPhone(
            slot: spot.slot, frame: placed, screen: placed.insetBy(dx: bezel, dy: bezel),
            cornerRadius: width * (isBare ? 0.07 : 0.16), screenCornerRadius: width * (isBare ? 0.07 : 0.13),
            rotation: job.isMirrored ? -spot.rotation : spot.rotation,
            color: isBare ? TemplateColor(red: 0, green: 0, blue: 0, alpha: 0) : TemplateColor(job.template.device.color) ?? .black,
            shadowOffset: max(1, width * 0.04), shadowRadius: max(2, width * 0.14), isBare: isBare
        )
    }

    /// The font the template's headline uses for `text` in the language's
    /// script.
    private func fontName(for text: String, template: ScreenshotTemplate, locale: StoreLocale) -> String {
        FontChoice.choose(
            font: template.caption.headline.font, for: text.isEmpty ? " " : text, script: ScreenshotScript(locale: locale),
            fonts: template.fonts, catalog: catalog
        ).fontName
    }

    // MARK: - Headline

    private struct FittedHeadline {
        var fit: CaptionFit
        var fontName: String
        var style: TemplateTextStyle
        var emphasisFont: String?
    }

    /// Where the text column goes, before mirroring.
    private struct TextPlacement {
        var x: CGFloat
        var top: CGFloat
        var width: CGFloat
        var lineHeight: CGFloat
        var alignment: LayoutTextAlignment
        var isRightToLeft: Bool
        var isMirrored: Bool
    }

    /// From the full size down to `smallestScale` of it, the first size at
    /// which every word fits the box's width and the lines its height.
    private func fitHeadline(
        _ raw: String, template: ScreenshotTemplate, locale: StoreLocale, fullSize: CGFloat, box: CGRect, maxLines: Int
    ) -> FittedHeadline {
        let script = ScreenshotScript(locale: locale)
        var style = template.caption.headline
        let language = Locale(identifier: locale.code)
        let text = style.isUppercase ? raw.uppercased(with: language) : raw
        let choice = FontChoice.choose(font: style.font, for: text, script: script, fonts: template.fonts, catalog: catalog)
        style.size = Double(fullSize)
        style.min = Double(fullSize) * Self.smallestScale
        var block = CaptionFitter.Block(text: text, style: style, fontName: choice.fontName)
        var emphasisFont: String?
        if let emphasis = style.emphasis {
            let font = emphasis.font.flatMap { catalog.covers($0, text) ? $0 : nil } ?? choice.fontName
            emphasisFont = font
            block.alternate = CaptionFitter.Face(fontName: font, weight: emphasis.weight ?? style.weight, isItalic: emphasis.italic ?? style.isItalic)
        }
        var width = box.width
        if let highlight = style.highlight { width = max(1, width - fullSize * CGFloat(highlight.horizontalPadding * 2 + 0.08)) }
        let fitter = CaptionFitter(catalog: catalog)
        let fitBox = CaptionFitter.Box(unit: 1, width: width, locale: language, script: script)
        var fit = CaptionFit(
            text: text, lines: [], size: style.size, fullSize: style.size, minimumSize: style.min,
            maxLines: 1, fits: true, hasWideWord: false, fill: 0
        )
        guard !fit.isEmpty else { return FittedHeadline(fit: fit, fontName: choice.fontName, style: style, emphasisFont: emphasisFont) }
        for size in fitter.sizes(full: style.size, minimum: style.min, shrink: true) where size > 0 {
            let breaks = fitter.lines(block, size: size, box: fitBox, hyphenate: template.fit.hyphenate)
            let lineHeight = CGFloat(size * style.lineHeight)
            let room = max(1, min(maxLines, Int((box.height + 0.5) / lineHeight)))
            fit.lines = breaks.lines
            fit.size = size
            fit.maxLines = room
            fit.hasWideWord = breaks.hasWideWord
            fit.fits = !breaks.hasWideWord && breaks.lines.count <= room
            if fit.fits { break }
        }
        return FittedHeadline(fit: fit, fontName: choice.fontName, style: style, emphasisFont: emphasisFont)
    }

    private func measure(_ text: String, fontName: String, weight: Int, italic: Bool, size: CGFloat, tracking: CGFloat) -> CGFloat {
        let font = CaptionFitter(catalog: catalog).font(CaptionFitter.Face(fontName: fontName, weight: weight, isItalic: italic), pixelSize: size)
        return ceil(CaptionMeasurer.width(of: text, font: font, tracking: tracking))
    }

    private func lines(
        _ fitted: FittedHeadline, template: ScreenshotTemplate, placement: TextPlacement, place: (CGFloat, CGFloat) -> CGFloat
    ) -> [LayoutTextLine] {
        let fit = fitted.fit
        guard !fit.isEmpty else { return [] }
        let style = fitted.style
        let pixelSize = CGFloat(fit.size)
        let alignment = placement.alignment
        let ink = TemplateColor(template.caption.ink) ?? .white
        let count = fit.lines.count
        let x = place(placement.x, placement.width)
        return fit.lines.enumerated().map { index, text in
            var line = LayoutTextLine(
                text: text, fontName: fitted.fontName, weight: style.weight, pixelSize: pixelSize,
                frame: CGRect(x: x, y: placement.top + CGFloat(index) * placement.lineHeight, width: placement.width, height: placement.lineHeight),
                alignment: alignment, color: ink, tracking: CGFloat(style.tracking ?? 0) * pixelSize,
                isRightToLeft: placement.isRightToLeft, isOverflow: !fit.fits && index >= fit.maxLines,
                isItalic: style.isItalic, shadow: style.shadow.flatMap { TemplateShadow($0) }
            )
            if let emphasis = style.emphasis, emphasis.applies(toLine: index, of: count) {
                line.fontName = fitted.emphasisFont ?? fitted.fontName
                line.weight = emphasis.weight ?? style.weight
                line.isItalic = emphasis.italic ?? style.isItalic
                if let color = emphasis.color.flatMap(TemplateColor.init) { line.color = color }
            }
            if let highlight = style.highlight {
                let sign: Double = (index.isMultiple(of: 2) ? 1 : -1) * (placement.isMirrored ? -1 : 1)
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
