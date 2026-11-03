//
//  ScreenshotLayoutEngine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Lays out one render: the template resolved for the slot, the caption
/// fitted with the locale's fonts and line breaking, the caption box
/// reserved at its full height so the device never moves between locales,
/// then the device (or the full-bleed capture) below it, or above it when
/// the caption sits at the bottom, and the slot's decorations. Mirrors the
/// layout in right-to-left locales when `rtl.mirror` is on.
struct ScreenshotLayoutEngine {
    var catalog: ScreenshotFontCatalog = .standard

    /// The space between headline and subhead, as a fraction of the canvas
    /// height.
    static let subheadGap = 0.012

    /// The least space under a caption placed below the device, as a
    /// fraction of the canvas height.
    static let belowMinimumBottom = 0.05

    /// What every step of one layout needs.
    struct Context {
        var template: ScreenshotTemplate
        var slot: Int
        var canvas: ScreenshotCanvas
        var locale: StoreLocale
        var script: ScreenshotScript
        var isRightToLeft: Bool
        var isMirrored: Bool
        var isHero: Bool
    }

    func layout(
        _ template: ScreenshotTemplate,
        slot: Int,
        locale: StoreLocale,
        displayType: ScreenshotDisplayType,
        caption: ScreenshotCaption?,
        captureSize: PixelSize? = nil,
        companionSize: PixelSize? = nil
    ) -> ScreenshotLayout {
        let resolved = template.resolved(forSlot: slot)
        let orientation = resolved.canvas.following(captureSize, on: displayType).orientation(for: displayType)
        // iPhone Duo's closed screenshots frame the folded phone; with a
        // companion, the folded one stands beside the unfolded one.
        let isCover = displayType == .iPhoneDuo && captureSize.map(CaptureSizeRules.isDuoOuterDisplay) == true
        let pair = displayType == .iPhoneDuo && !isCover ? companionSize : nil
        let canvas = ScreenshotCanvas(display: displayType, orientation: orientation, isCoverDisplay: isCover)
        let script = ScreenshotScript(locale: locale)
        let isRightToLeft = locale.isRTL || script.isRightToLeft
        let isMirrored = isRightToLeft && resolved.rightToLeft.mirror
        let context = Context(
            template: resolved, slot: slot, canvas: canvas, locale: locale, script: script,
            isRightToLeft: isRightToLeft, isMirrored: isMirrored, isHero: template.isHero(slot: slot)
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
        switch displayType {
        case .watch:
            result.captionBox = .zero
            result.screen = CGRect(origin: .zero, size: canvas.size)
            result.isFullBleed = true
            return result
        case .visionPro:
            let top = 0.07 * height
            result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: captionHeight)
            let aspect = captureSize.flatMap { $0.width > 0 ? CGFloat($0.height) / CGFloat($0.width) : nil } ?? 0.75
            placeWindow(in: &result, top: top + captionHeight + 0.05 * height, hasCaption: captionHeight > 0, aspect: min(max(aspect, 0.5625), 1.25))
            result.lines = lines(fitted, box: result.captionBox, context: context)
            return result
        default:
            break
        }
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
                result.screen = CGRect(origin: .zero, size: canvas.size)
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
        result.lines = lines(fitted, box: result.captionBox, context: context)
        result.decorations = decorations(context: context, fontName: fitted.headlineFont.fontName)
        return result
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

    /// The device under a caption at the top, or over one at the bottom,
    /// leaning out of the top edge then: its bottom sits a gap above the
    /// caption, raised by however far its angle makes it stick out.
    /// iPhone Duo closed: the folded phone, its cover display's shape. With
    /// a `companion` (both, side by side), the pair instead.
    private func placeDevice(
        in layout: inout ScreenshotLayout, context: Context, captionTop: CGFloat, captionHeight: CGFloat, below: Bool, companion: PixelSize?
    ) {
        let template = context.template
        let canvas = layout.canvas
        let width = canvas.width
        let height = canvas.height
        let gap = template.caption.gap * height
        let top = below ? 0 : captionTop + captionHeight + gap
        guard template.device.show else {
            let side = template.safeArea.side * width
            let screenHeight = below ? captionTop - gap : height - top
            layout.screen = CGRect(x: side, y: top, width: width - 2 * side, height: max(0, screenHeight))
            layout.screenCornerRadius = 0.05 * width
            layout.screenHasShadow = true
            if let companion { placeFloatingPair(in: &layout, companion: companion) }
            return
        }
        if let companion {
            let span = DuoPairSpan(top: top, captionTop: captionTop, gap: gap, below: below)
            placeDevicePair(in: &layout, context: context, span: span, companion: companion)
            return
        }
        let shape = canvas.isCoverDisplay ? Self.coverShape : Self.deviceShape(for: canvas.display)
        let screenAspect = canvas.isCoverDisplay ? Self.coverAspect : height / width
        let bezelRatio = shape.bezel
        var deviceWidth = template.device.width * width * (context.isHero ? 0.96 : 1)
        var deviceHeight = deviceWidth * (1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio * deviceWidth
        let maximumHeight = below ? captionTop - gap + 0.25 * height : height * (1 + template.device.bleed) - top
        if canvas.isLandscape, deviceHeight > maximumHeight {
            deviceWidth = maximumHeight / ((1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio)
            deviceHeight = maximumHeight
        }
        let tilt = template.device.tilt ?? .flat
        let lift = LayoutTilt.lift(for: tilt, size: CGSize(width: deviceWidth, height: deviceHeight))
        var y = top
        if below {
            y = captionTop - gap - deviceHeight - lift
        } else if canvas.isLandscape {
            // A landscape device fills the height under the caption, so a
            // corner its angle raises would land on the caption.
            y += lift
        }
        y += CGFloat(template.device.shiftDown ?? 0) * height
        var offset = template.device.offset * width * (context.slot.isMultiple(of: 2) ? 1 : -1) + (template.device.shiftRight ?? 0) * width
        if layout.isMirrored { offset = -offset }
        let bezel = bezelRatio * deviceWidth
        let frame = CGRect(x: (width - deviceWidth) / 2 + offset, y: y, width: deviceWidth, height: deviceHeight)
        let screen = frame.insetBy(dx: bezel, dy: bezel)
        let island = shape.hasIsland ? CGRect(
            x: screen.midX - screen.width * 0.15, y: screen.minY + screen.width * 0.03,
            width: screen.width * 0.3, height: screen.width * 0.085
        ) : nil
        layout.device = LayoutDevice(
            frame: frame, cornerRadius: deviceWidth * shape.corner, bezel: bezel,
            color: TemplateColor(template.device.color) ?? .black, island: island,
            shadowOffset: height * 0.012, shadowRadius: height * 0.04,
            tilt: tilt.isFlat ? nil : LayoutTilt(tilt, isMirrored: layout.isMirrored, center: CGPoint(x: frame.midX, y: frame.midY))
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
