//
//  ScreenshotLayoutEngine.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Lays out one render: the template resolved for the slot, the caption
/// fitted with the locale's fonts and line breaking, the caption box
/// reserved at its full height so the device never moves between locales
/// (or sized to the real lines when the headline is tight), then the device
/// (or the full-bleed capture) below it, or above it when the caption sits
/// at the bottom, a Two phones slot's phone behind, and the slot's
/// decorations, kept off the headline where they ask to be. Mirrors the
/// layout in right-to-left locales when `rtl.mirror` is on.
struct ScreenshotLayoutEngine {
    var catalog: ScreenshotFontCatalog = .standard
    /// The app's App Store rating per country, which laurels show.
    var ratings: StoreRatings = .unchecked
    /// The app's 5-star App Store reviews per country, which a Reviews
    /// slot shows.
    var reviews: StoreReviews = .none

    /// The space between headline and subhead, as a fraction of the canvas
    /// height.
    static let subheadGap = 0.012

    /// The space between the kicker line and the headline, as a fraction
    /// of the canvas height.
    static let kickerGap = 0.004

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
        /// Two phones: the slot before it's capture stands behind.
        var isPair = false
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
        let orientation = template.resolved(forSlot: slot).canvas.following(captureSize, on: displayType).orientation(for: displayType)
        // Lying down (iPad, Mac), the template's landscape overrides apply.
        let resolved = template.resolved(forSlot: slot, isLandscape: orientation == .landscape && displayType.isRendered)
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
            isRightToLeft: isRightToLeft, isMirrored: isMirrored, isHero: template.isHero(slot: slot), isPair: template.isPair(slot: slot)
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
        let captionHeight = frame.height
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
        if template.isQuotes(slot: slot) {
            guard reviews.quotes(for: locale).isEmpty else {
                layoutQuotes(in: &result, context: context, fitted: fitted)
                return result
            }
            // No review to quote: the slot shows its capture like the
            // others, and says why (see `LayoutReviews.showsCapture`).
            result.reviews = LayoutReviews(own: 0, borrowed: 0, isChecked: reviews.isChecked(locale), showsCapture: true)
        }
        placeCaption(frame, in: &result, context: context, isCover: isCover, pair: pair)
        result.lines = lines(fitted, box: result.captionBox, context: context)
        let headlineLines = fitted.headline.isEmpty ? [] : Array(result.lines.prefix(fitted.headline.lines.count))
        result.decorations = decorations(
            context: context, fontName: fitted.headlineFont.fontName, captionBox: result.captionBox, headlineLines: headlineLines,
            device: result.device
        )
        result.unratedLaurels = unratedLaurels(context: context)
        makeRoomForRating(in: &result, context: context, fitted: fitted, headlineLines: headlineLines, pair: pair)
        return result
    }

    /// Reviews: the caption at the top, the reviews under it, no device
    /// whatever the placement.
    private func layoutQuotes(in result: inout ScreenshotLayout, context: Context, fitted: FittedCaption) {
        let frame = fitted.frame
        let top = context.template.safeArea.top * result.canvas.height
        result.captionBox = CGRect(x: frame.boxX, y: top, width: frame.boxWidth, height: frame.height)
        result.lines = lines(fitted, box: result.captionBox, context: context)
        placeReviews(in: &result, context: context, top: top + frame.height, headlineFont: fitted.headlineFont.fontName)
        let headlineLines = fitted.headline.isEmpty ? [] : Array(result.lines.prefix(fitted.headline.lines.count))
        result.decorations += decorations(
            context: context, fontName: fitted.headlineFont.fontName, captionBox: result.captionBox, headlineLines: headlineLines
        )
    }

    /// iPhone is the look the templates are drawn for; on wider canvases a
    /// laurel can land on the device. A laurel or badge with no room beside
    /// the device keeps the device above or under it, as on iPhone, or else
    /// moves the device aside to make that room.
    private func makeRoomForRating(
        in result: inout ScreenshotLayout, context: Context, fitted: FittedCaption, headlineLines: [LayoutTextLine], pair: PixelSize?
    ) {
        let canvas = result.canvas
        let placement = context.template.caption.placement
        let isWider = canvas.isLandscape || canvas.display != .iPhone
        guard isWider, placement != .band, pair == nil, result.device != nil,
              let rating = Self.ratingOnDevice(in: result, share: canvas.isLandscape ? 0 : Self.coveredRatingShare)
        else { return }
        let below = placement == .below
        let floor = below ? nil : Self.ratingFloor(under: rating, in: result)
        let ceiling = below ? Self.ratingCeiling(over: rating, in: result) : nil
        placeDevice(
            in: &result, context: context, captionTop: result.captionBox.minY, captionHeight: fitted.frame.height, below: below,
            companion: pair, floor: floor, ceiling: ceiling,
            nudge: floor == nil && ceiling == nil ? Self.nudge(making: rating, in: result) : 0
        )
        result.decorations = decorations(
            context: context, fontName: fitted.headlineFont.fontName, captionBox: result.captionBox, headlineLines: headlineLines,
            device: result.device
        )
        result.unratedLaurels = unratedLaurels(context: context)
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
    func placeDevice(
        in layout: inout ScreenshotLayout, context: Context, captionTop: CGFloat, captionHeight: CGFloat, below: Bool, companion: PixelSize?,
        floor: CGFloat? = nil, ceiling: CGFloat? = nil, nudge: CGFloat = 0
    ) {
        let template = context.template
        let canvas = layout.canvas
        let width = canvas.width
        let height = canvas.height
        let gap = template.caption.gap * height
        let top = below ? 0 : captionTop + captionHeight + gap
        let span = DuoPairSpan(top: top, captionTop: captionTop, gap: gap, below: below)
        guard template.device.show else {
            placeBareScreen(in: &layout, template: template, span: span, companion: companion)
            return
        }
        layout.emptyScreen = template.device.emptyScreenColor
        if let companion {
            placeDevicePair(in: &layout, context: context, span: span, companion: companion)
            return
        }
        let shape = canvas.isCoverDisplay ? Self.coverShape : Self.deviceShape(for: canvas.display)
        let screenAspect = canvas.isCoverDisplay ? Self.coverAspect : height / width
        let bezelRatio = shape.bezel
        let isLaptop = canvas.display == .mac
        // However far the template lets devices bleed, or pins or shifts
        // them down, the folded Duo stands whole above this floor: its
        // squat shape is what tells it from an iPhone.
        let floor = canvas.isCoverDisplay ? min(floor ?? .infinity, 0.96 * height) : floor
        let size = deviceSize(context: context, span: span, shape: shape, screenAspect: screenAspect, floor: floor, ceiling: ceiling)
        let deviceWidth = size.width
        let deviceHeight = size.height
        let tilt = template.device.tilt ?? .flat
        let lift = LayoutTilt.lift(for: tilt, size: CGSize(width: deviceWidth, height: deviceHeight))
        let baseHeight = isLaptop ? deviceHeight * Self.laptopBaseHeight : 0
        var y = top
        if below {
            y = captionTop - gap - deviceHeight - baseHeight - lift
        } else if canvas.isLandscape {
            // A landscape device fills the height under the caption, so a
            // corner its angle raises would land on the caption.
            y += lift
        }
        // A pinned top holds unless the caption needs the room.
        if !below, let pinned = template.device.top { y = max(y, CGFloat(pinned) * height) }
        y += CGFloat(template.device.shiftDown ?? 0) * height
        // Raised, a MacBook may use up the gap but never reach the caption.
        if isLaptop, !below { y = max(y, top - gap + lift) }
        // Its base, and the corner its angle lowers, stay on the canvas,
        // over a laurel it makes room for.
        if isLaptop { y = min(y, 0.98 * height - deviceHeight - baseHeight - lift) }
        if let floor, !below { y = min(y, floor - deviceHeight - baseHeight - lift) }
        var offset = template.device.offset * width * (context.slot.isMultiple(of: 2) ? 1 : -1) + (template.device.shiftRight ?? 0) * width
        if layout.isMirrored { offset = -offset }
        offset += nudge
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
            tilt: tilt.isFlat ? nil : LayoutTilt(tilt, isMirrored: layout.isMirrored, center: CGPoint(x: frame.midX, y: frame.midY)),
            base: isLaptop ? Self.laptopBase(under: frame) : nil,
            spine: canvas.isCoverDisplay ? Self.coverSpine(width: deviceWidth) : nil
        )
        layout.screen = screen
        layout.screenCornerRadius = deviceWidth * shape.screenCorner
        if context.isPair, !canvas.isLandscape, !canvas.isCoverDisplay, let device = layout.device {
            placePhoneBehind(in: &layout, front: device, template: template, captionBottom: top, screenCornerRadius: layout.screenCornerRadius)
        }
    }

    /// No device: the capture itself, rounded and shadowed, between the
    /// safe area's sides and from the caption to the canvas's edge.
    private func placeBareScreen(in layout: inout ScreenshotLayout, template: ScreenshotTemplate, span: DuoPairSpan, companion: PixelSize?) {
        let width = layout.canvas.width
        let side = template.safeArea.side * width
        let screenHeight = span.below ? span.captionTop - span.gap : layout.canvas.height - span.top
        layout.screen = CGRect(x: side, y: span.top, width: width - 2 * side, height: max(0, screenHeight))
        layout.screenCornerRadius = 0.05 * width
        layout.screenHasShadow = true
        if let companion { placeFloatingPair(in: &layout, companion: companion) }
    }

    /// The device's size: the template's width, shrunk so a landscape
    /// device, a MacBook on its base, or a device kept clear of a laurel
    /// (`floor`, `ceiling`) fits between the caption and the canvas's edge.
    private func deviceSize(
        context: Context, span: DuoPairSpan, shape: DeviceShape, screenAspect: CGFloat, floor: CGFloat? = nil, ceiling: CGFloat? = nil
    ) -> CGSize {
        let template = context.template
        let canvas = context.canvas
        let height = canvas.height
        let top = span.top
        let below = span.below
        let captionTop = span.captionTop
        let gap = span.gap
        let bezelRatio = shape.bezel
        let isLaptop = canvas.display == .mac
        var deviceWidth = template.device.width * canvas.width * (context.isHero ? 0.96 : 1) * (isLaptop ? Self.laptopWidth : 1)
        var deviceHeight = deviceWidth * (1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio * deviceWidth
        // A MacBook stands on its base inside the canvas, never off its edge;
        // the folded iPhone Duo stands whole, or its squat shape (what tells
        // it from an iPhone) runs off the edge.
        var maximumHeight = isLaptop
            ? (below ? captionTop - gap - 0.1 * height : 0.9 * height - top)
            : canvas.isCoverDisplay
            ? (below ? captionTop - gap - 0.04 * height : 0.96 * height - top)
            : (below ? captionTop - gap + 0.25 * height : height * (1 + template.device.bleed) - top)
        if let floor, !below { maximumHeight = min(maximumHeight, floor - top) }
        if let ceiling, below { maximumHeight = min(maximumHeight, captionTop - gap - ceiling) }
        if canvas.isLandscape || canvas.isCoverDisplay, deviceHeight > maximumHeight {
            deviceWidth = maximumHeight / ((1 - 2 * bezelRatio) * screenAspect + 2 * bezelRatio)
            deviceHeight = maximumHeight
        }
        guard isLaptop || (floor != nil && !below) || (ceiling != nil && below) else {
            return CGSize(width: deviceWidth, height: deviceHeight)
        }
        // The lid, its base and the corners its angle raises and lowers all
        // fit between the caption and the canvas's edge (or the laurel under
        // or over the device).
        let corners = 2 * LayoutTilt.lift(for: template.device.tilt ?? .flat, size: CGSize(width: deviceWidth, height: deviceHeight))
        let needed = deviceHeight * (1 + (isLaptop ? Self.laptopBaseHeight : 0)) + corners
        let bottom = min(0.98 * height, floor ?? .infinity)
        let available = below ? captionTop - gap - max(0.02 * height, ceiling ?? 0) : bottom - top
        guard needed > available, needed > 0 else { return CGSize(width: deviceWidth, height: deviceHeight) }
        let scale = max(0, available) / needed
        return CGSize(width: deviceWidth * scale, height: deviceHeight * scale)
    }

    /// Two phones: a phone like the front one, flat, behind it at
    /// `device.pair` (higher up, partly off the edge), never over the
    /// caption, mirrored in right-to-left locales. The canvas crops what
    /// runs off.
    private func placePhoneBehind(
        in layout: inout ScreenshotLayout, front: LayoutDevice, template: ScreenshotTemplate, captionBottom: CGFloat, screenCornerRadius: CGFloat
    ) {
        let width = layout.canvas.width
        let height = layout.canvas.height
        let pair = template.device.pair ?? .standard
        let size = front.frame.size
        var x = (width - size.width) / 2 + CGFloat(pair.shiftRight) * width
        if layout.isMirrored { x = width - x - size.width }
        let y = pair.top.map { max(CGFloat($0) * height, captionBottom) } ?? captionBottom - 0.12 * height
        let frame = CGRect(origin: CGPoint(x: x, y: y), size: size)
        var device = front
        device.frame = frame
        device.tilt = nil
        device.island = front.island.map { $0.offsetBy(dx: frame.minX - front.frame.minX, dy: frame.minY - front.frame.minY) }
        layout.companion = LayoutCompanion(
            device: device, screen: frame.insetBy(dx: front.bezel, dy: front.bezel), screenCornerRadius: screenCornerRadius, isBehind: true
        )
    }

    /// The device with its base, as laurels and badges keep clear of it.
    static func body(of device: LayoutDevice) -> CGRect {
        device.frame.union(device.base ?? device.frame)
    }

    /// A laurel or badge drawn on the device (one that couldn't stand
    /// beside it), more than `share` of it covered.
    static func ratingOnDevice(in layout: ScreenshotLayout, share: CGFloat = 0) -> CGRect? {
        guard let device = layout.device else { return nil }
        let body = body(of: device)
        return layout.decorations.first { decoration in
            guard decoration.kind == .laurel || decoration.kind == .badge, decoration.frame.intersects(body) else { return false }
            let covered = decoration.frame.intersection(body)
            let area = decoration.frame.width * decoration.frame.height
            return area > 0 && covered.width * covered.height / area > share
        }?.frame
    }

    /// How much of a laurel a portrait device may cover, as on iPhone,
    /// where a corner of the phone overlaps it by design.
    static let coveredRatingShare: CGFloat = 0.25

    /// The bottom of a laurel over the device's upper half, plus a gap:
    /// where the device, standing on a caption at the bottom, has to
    /// start. Nil when it's lower down, or when the device would get
    /// shorter than a third of the canvas.
    static func ratingCeiling(over rating: CGRect, in layout: ScreenshotLayout) -> CGFloat? {
        guard let device = layout.device, rating.midY < body(of: device).midY else { return nil }
        let ceiling = rating.maxY + 0.02 * layout.canvas.height
        return layout.captionBox.minY - ceiling >= layout.canvas.height / 3 ? ceiling : nil
    }

    /// The top of a laurel on the device's lower half, less a gap: where
    /// the device has to end. Nil when it's higher up, or when the device
    /// would get shorter than a third of the canvas.
    static func ratingFloor(under rating: CGRect, in layout: ScreenshotLayout) -> CGFloat? {
        guard let device = layout.device, rating.midY > body(of: device).midY else { return nil }
        let floor = rating.minY - 0.02 * layout.canvas.height
        return floor - layout.captionBox.maxY >= layout.canvas.height / 3 ? floor : nil
    }

    /// How far the device moves sideways, toward the side with less room,
    /// so the laurel fits beside it on the other: running off the canvas's
    /// edge by at most 30% of its width.
    static func nudge(making rating: CGRect, in layout: ScreenshotLayout) -> CGFloat {
        guard let device = layout.device else { return 0 }
        let width = layout.canvas.width
        let body = body(of: device).insetBy(dx: -0.02 * width, dy: 0)
        let left = body.minX - 0.02 * width
        let right = width - 0.02 * width - body.maxX
        let shift = min(max(0, rating.width - max(left, right)), 0.3 * device.frame.width)
        return left >= right ? shift : -shift
    }

    /// A MacBook's lid is this much of the template's device width: with
    /// its base it's wider than the lid.
    static let laptopWidth: CGFloat = 0.86

    /// A MacBook's base, as a fraction of the lid's height.
    static let laptopBaseHeight: CGFloat = 0.055

    /// A MacBook's base under `lid`: 7% wider on each side, its top a hair
    /// under the lid's bottom edge.
    static func laptopBase(under lid: CGRect) -> CGRect {
        let overhang = lid.width * 0.07
        return CGRect(
            x: lid.minX - overhang, y: lid.maxY - lid.height * 0.004,
            width: lid.width + 2 * overhang, height: lid.height * laptopBaseHeight
        )
    }

    /// The frame drawn around the capture, as fractions of the device's
    /// width: an iPhone's thin bezel, round corners and Dynamic Island; an
    /// iPad's squarer corners; iPhone Duo unfolded between the two, with
    /// no island on its inner display; a MacBook's lid, thinnest of all.
    static func deviceShape(for display: ScreenshotDisplayType) -> DeviceShape {
        switch display {
        case .mac: DeviceShape(bezel: 0.016, corner: 0.026, screenCorner: 0.012, hasIsland: false)
        case .iPad: DeviceShape(bezel: 0.028, corner: 0.05, screenCorner: 0.035, hasIsland: false)
        case .iPhoneDuo: DeviceShape(bezel: 0.03, corner: 0.09, screenCorner: 0.066, hasIsland: false)
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
