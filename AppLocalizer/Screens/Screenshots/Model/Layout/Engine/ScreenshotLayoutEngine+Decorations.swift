//
//  ScreenshotLayoutEngine+Decorations.swift
//  AppLocalizer
//

import CoreGraphics
import CoreText
import Foundation

// Placing the slot's shapes, laurels, badges and props. `x` and `w` are
// fractions of the canvas width, `y` and `h` of its height, and a decoration
// without a height is square. Right-to-left locales mirror the position and
// the angle and flip shapes and props, while laurels and badges keep their
// text readable. A prop can be anchored to the caption (under its box, or
// at the end of the headline's first line), and one that asks to avoid the
// headline moves below the caption, narrows or hides where a language's
// lines run into it. Hidden ones aren't drawn. In landscape, laurels, badges
// and sparkles keep their portrait size (relative to the short side) and
// stay inside the canvas. A laurel showing the App Store's rating takes the
// country's average, written the locale's way with Latin digits, and is left
// out where the app has no ratings yet.
extension ScreenshotLayoutEngine {
    /// The space between a prop and the text it steps aside from or
    /// follows, as a fraction of the canvas width.
    static let propGap = 0.012

    /// The narrowest a squeezed prop may get, as a fraction of the canvas
    /// width; narrower, it hides.
    static let narrowestProp = 0.03

    func decorations(
        context: Context, fontName: String, captionBox: CGRect, headlineLines: [LayoutTextLine], device: LayoutDevice? = nil
    ) -> [LayoutDecoration] {
        let ink = headlineLines.map(inkBox)
        return (context.template.decorations ?? []).compactMap { decoration in
            guard !decoration.isHidden else { return nil }
            var placed = place(decoration, context: context, captionBox: captionBox, firstLine: headlineLines.first, firstInk: ink.first)
            if decoration.isRating, context.canvas.isLandscape, let device {
                placed = besideDevice(placed, device: device, canvasWidth: context.canvas.width)
            }
            guard let frame = avoiding(ink, with: placed, decoration: decoration, context: context, captionBox: captionBox) else { return nil }
            var result = laidOut(decoration, frame: frame, context: context, fontName: fontName)
            if decoration.showsStoreRating {
                switch ratings.status(for: context.locale) {
                case let .rated(average):
                    result.text = Self.ratingText(average, locale: context.locale)
                    result.isFromStore = true
                case .unrated: return nil
                case .unknown: break
                }
            }
            return result
        }
    }

    /// How many of the slot's laurels are left out because the app has no
    /// App Store rating in the locale's country yet.
    func unratedLaurels(context: Context) -> Int {
        guard ratings.status(for: context.locale) == .unrated else { return 0 }
        return (context.template.decorations ?? []).count { !$0.isHidden && $0.showsStoreRating }
    }

    /// Where it goes before it meets the text: on the canvas (mirrored in
    /// right-to-left locales), under the caption box, or at the end of the
    /// headline's first line, kept on the canvas.
    private func place(
        _ decoration: TemplateDecoration, context: Context, captionBox: CGRect, firstLine: LayoutTextLine?, firstInk: CGRect?
    ) -> CGRect {
        let width = context.canvas.width
        let height = context.canvas.height
        let keepsSize = context.canvas.isLandscape && Self.keepsPortraitSize(decoration)
        let frameWidth = CGFloat(decoration.width) * (keepsSize ? min(width, height) : width)
        let frameHeight = decoration.height.map { fraction in
            // The portrait proportions: an iPhone canvas is 1320 × 2868.
            keepsSize ? frameWidth * CGFloat(fraction * 2868) / CGFloat(decoration.width * 1320) : CGFloat(fraction) * height
        } ?? frameWidth
        var x = CGFloat(decoration.x) * width
        var y = CGFloat(decoration.y) * height
        if keepsSize {
            x = min(max(x, 0.02 * width), width - frameWidth - 0.02 * width)
            y = min(max(y, 0.02 * height), height - frameHeight - 0.03 * height)
        }
        if decoration.anchor == .caption { y = captionBox.maxY + CGFloat(decoration.y) * height }
        if decoration.anchor == .firstLineEnd, let firstLine, let firstInk {
            let gap = CGFloat(Self.propGap) * width
            x = context.isRightToLeft
                ? max(firstInk.minX - gap - frameWidth, -0.08 * frameWidth)
                : min(firstInk.maxX + gap, width - frameWidth * 0.92)
            y = firstLine.frame.minY + (firstLine.frame.height - frameHeight) / 2 - 0.12 * frameHeight
        } else if context.isMirrored {
            x = width - x - frameWidth
        }
        return CGRect(x: x, y: y, width: frameWidth, height: frameHeight)
    }

    /// `frame` kept off the headline's letters, the way the decoration
    /// asks (a prop at the end of the first line hides), or nil when it
    /// hides. One that doesn't ask may overlap.
    private func avoiding(
        _ ink: [CGRect], with frame: CGRect, decoration: TemplateDecoration, context: Context, captionBox: CGRect
    ) -> CGRect? {
        guard decoration.avoid != nil || decoration.anchor == .firstLineEnd else { return frame }
        let hits = ink.filter { $0.intersects(frame) }
        guard !hits.isEmpty else { return frame }
        let width = context.canvas.width
        let gap = CGFloat(Self.propGap) * width
        let narrowest = CGFloat(Self.narrowestProp) * width
        var result = frame
        switch decoration.avoid ?? .hide {
        case .down:
            result.origin.y = max(frame.minY, captionBox.maxY + 0.006 * context.canvas.height)
        case .squeeze where context.isMirrored:
            let edge = (hits.map(\.minX).min() ?? frame.minX) - gap
            guard edge - frame.minX >= narrowest else { return nil }
            result.size.width = edge - frame.minX
        case .squeeze:
            let edge = (hits.map(\.maxX).max() ?? frame.minX) + gap
            guard frame.maxX - edge >= narrowest else { return nil }
            result = CGRect(x: edge, y: frame.minY, width: frame.maxX - edge, height: frame.height)
        case .hide:
            return nil
        }
        return result
    }

    /// A laurel or badge a landscape canvas puts on the device (portrait
    /// sets it in the room above or below the phone) moves into the room
    /// beside it, its own side first, at the same height, down to 60% of
    /// its size where the room is narrower. Left where it is when neither
    /// side has room.
    private func besideDevice(_ frame: CGRect, device: LayoutDevice, canvasWidth width: CGFloat) -> CGRect {
        let body = device.frame.union(device.base ?? device.frame).insetBy(dx: -0.02 * width, dy: 0)
        guard frame.intersects(body), frame.width > 0 else { return frame }
        let margin = 0.02 * width
        let rooms: [(minX: CGFloat, width: CGFloat)] = [(margin, body.minX - margin), (body.maxX, width - margin - body.maxX)]
        let ownFirst = frame.midX < body.midX ? rooms : rooms.reversed()
        let room = ownFirst.first { $0.width >= frame.width } ?? ownFirst.max { $0.width < $1.width }
        guard let room, room.width >= frame.width * Self.smallestBesideDevice else { return frame }
        let scale = min(1, room.width / frame.width)
        let size = CGSize(width: frame.width * scale, height: frame.height * scale)
        return CGRect(x: room.minX + (room.width - size.width) / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
    }

    /// How small a laurel or badge may get to stand beside the device.
    static let smallestBesideDevice: CGFloat = 0.6

    /// Laurels, badges and sparkles: sized by the short side in landscape,
    /// so they don't grow with the wider canvas.
    static func keepsPortraitSize(_ decoration: TemplateDecoration) -> Bool {
        decoration.isRating || (decoration.type == .shape && decoration.shape == .sparkle)
    }

    /// "4.8", "4,7": the App Store's one decimal, with the locale's
    /// separator and Latin digits.
    static func ratingText(_ average: Double, locale: StoreLocale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: locale.code.replacingOccurrences(of: "-", with: "_") + "@numbers=latn")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: average)) ?? String(format: "%.1f", average)
    }

    /// Where a line's letters are: as wide as its text, as tall as its
    /// font's capitals (within the line box).
    private func inkBox(_ line: LayoutTextLine) -> CGRect {
        let font = catalog.font(named: line.fontName, weight: line.weight, size: line.pixelSize, italic: line.isItalic)
        let textWidth = font.map { CaptionMeasurer.width(of: line.text, font: $0, tracking: line.tracking) } ?? line.frame.width
        let capHeight = font.map { CTFontGetCapHeight($0) } ?? line.pixelSize * 0.74
        let inkHeight = min(line.frame.height, capHeight)
        let frame = line.frame
        let minX = switch line.alignment {
        case .left: frame.minX
        case .center: frame.midX - textWidth / 2
        case .right: frame.maxX - textWidth
        }
        return CGRect(x: minX, y: frame.midY - inkHeight / 2, width: textWidth, height: inkHeight)
    }

    private func laidOut(_ decoration: TemplateDecoration, frame: CGRect, context: Context, fontName: String) -> LayoutDecoration {
        let color = TemplateColor(decoration.color) ?? .white
        let flips = decoration.type == .shape || decoration.type == .art
        var result = LayoutDecoration(
            kind: decoration.type, shape: decoration.shape, art: decoration.art, frame: frame,
            rotation: (decoration.rotation ?? 0) * (context.isMirrored ? -1 : 1),
            isFlipped: context.isMirrored && flips, opacity: decoration.opacity ?? 1, color: color,
            isFront: decoration.layer == .front, text: nil, textColor: color, fontName: fontName, textSize: 0, textWeight: 700,
            starColor: nil, starSize: 0, starGap: 0
        )
        switch decoration.type {
        case .shape, .art:
            break
        case .badge:
            result.text = decoration.value
            result.textColor = decoration.ink.flatMap(TemplateColor.init) ?? .white
            result.textSize = frame.width * 0.2
            result.textWeight = 800
        case .laurel:
            let side = min(frame.width, frame.height)
            result.text = decoration.value
            result.textColor = decoration.ink.flatMap(TemplateColor.init) ?? color
            result.textSize = side * 0.26
            result.textWeight = 700
            if decoration.stars == true {
                result.starColor = decoration.star.flatMap(TemplateColor.init) ?? color
                result.starSize = side * 0.075
                result.starGap = side * 0.03
            }
        }
        return result
    }
}
