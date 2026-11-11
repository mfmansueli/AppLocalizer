//
//  ScreenshotLayoutEngine+DuoPair.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// iPhone Duo folded: the phone on its cover display, alone (a closed
/// screenshot) or beside the unfolded Duo (both, side by side). Every
/// screenshot stays Apple's 2007 × 2853, either way up.
extension ScreenshotLayoutEngine {
    /// The folded phone's frame on the side it opens from: an iPhone's
    /// bezel, no island, and the cover display's corner from Apple's mask
    /// (the iPhone Duo simulator's), scaled the way the iPhone's own
    /// corners are. The hinge side is `coverSpine`'s.
    static let coverShape = DeviceShape(bezel: 0.034, corner: 0.124, screenCorner: 0.099, hasIsland: false)

    /// The folded phone's hinge, as fractions of its width: the mask's
    /// nearly square corners on that side, and the spine standing out.
    static func coverSpine(width deviceWidth: CGFloat) -> LayoutSpine {
        LayoutSpine(
            width: 0.06 * deviceWidth, overhang: 0.022 * deviceWidth,
            bodyCornerRadius: 0.03 * deviceWidth, screenCornerRadius: 0.008 * deviceWidth
        )
    }

    /// The cover display's height ÷ width, standing up (1398 × 2034).
    static var coverAspect: CGFloat {
        CGFloat(CaptureSizeRules.duoOuterSize.height) / CGFloat(CaptureSizeRules.duoOuterSize.width)
    }

    /// The space between the unfolded Duo and the folded one, as a
    /// fraction of the canvas width.
    static let pairGap: CGFloat = 0.035

    /// The room the pair has: under the caption from `top`, or over it,
    /// ending a gap above `captionTop`.
    struct DuoPairSpan {
        var top: CGFloat
        var captionTop: CGFloat
        var gap: CGFloat
        var below: Bool
    }

    /// The unfolded Duo (the canvas's shape) with the folded one beside it,
    /// at the same scale (a capture pixel is as big on both), within the
    /// device's width; the pair is centered, the folded one on the
    /// trailing side (leading when mirrored). Both stand flat and whole:
    /// a pair doesn't bleed off the edge.
    func placeDevicePair(in layout: inout ScreenshotLayout, context: Context, span: DuoPairSpan, companion: PixelSize) {
        let template = context.template
        let width = layout.canvas.width
        let height = layout.canvas.height
        let inner = Self.deviceShape(for: .iPhoneDuo)
        let cover = Self.coverShape
        let innerAspect = height / width
        let coverAspect = companion.width > 0 ? CGFloat(companion.height) / CGFloat(companion.width) : Self.coverAspect
        // The folded phone's width per unit of the unfolded one's.
        let ratio = CGFloat(max(companion.width, 1)) / width * (1 - 2 * inner.bezel) / (1 - 2 * cover.bezel)
        let pairGap = Self.pairGap * width
        let budget = template.device.width * width * (context.isHero ? 0.96 : 1)
        let heights = { (innerWidth: CGFloat) -> (inner: CGFloat, cover: CGFloat) in
            let coverWidth = innerWidth * ratio
            return (
                innerWidth * (1 - 2 * inner.bezel) * innerAspect + 2 * inner.bezel * innerWidth,
                coverWidth * (1 - 2 * cover.bezel) * coverAspect + 2 * cover.bezel * coverWidth
            )
        }
        var innerWidth = max(0, budget - pairGap) / (1 + ratio)
        let room = span.below ? span.captionTop - span.gap - 0.04 * height : height - span.top - 0.04 * height
        let tallest = max(heights(innerWidth).inner, heights(innerWidth).cover)
        if tallest > room, tallest > 0 { innerWidth *= max(0, room) / tallest }
        let sizes = heights(innerWidth)
        let coverWidth = innerWidth * ratio
        let left = (width - innerWidth - pairGap - coverWidth) / 2 + (template.device.shiftRight ?? 0) * width
        let shiftDown = CGFloat(template.device.shiftDown ?? 0) * height
        let originY = { (frameHeight: CGFloat) in (span.below ? span.captionTop - span.gap - frameHeight : span.top) + shiftDown }
        var innerFrame = CGRect(x: left, y: originY(sizes.inner), width: innerWidth, height: sizes.inner)
        var coverFrame = CGRect(x: left + innerWidth + pairGap, y: originY(sizes.cover), width: coverWidth, height: sizes.cover)
        if layout.isMirrored {
            coverFrame.origin.x = left
            innerFrame.origin.x = left + coverWidth + pairGap
        }
        let color = TemplateColor(template.device.color) ?? .black
        let innerBezel = inner.bezel * innerWidth
        let coverBezel = cover.bezel * coverWidth
        layout.device = LayoutDevice(
            frame: innerFrame, cornerRadius: innerWidth * inner.corner, bezel: innerBezel, color: color, island: nil,
            shadowOffset: height * 0.012, shadowRadius: height * 0.04, tilt: nil
        )
        layout.screen = innerFrame.insetBy(dx: innerBezel, dy: innerBezel)
        layout.screenCornerRadius = innerWidth * inner.screenCorner
        layout.companion = LayoutCompanion(
            device: LayoutDevice(
                frame: coverFrame, cornerRadius: coverWidth * cover.corner, bezel: coverBezel, color: color, island: nil,
                shadowOffset: height * 0.012, shadowRadius: height * 0.04, tilt: nil, spine: Self.coverSpine(width: coverWidth)
            ),
            screen: coverFrame.insetBy(dx: coverBezel, dy: coverBezel), screenCornerRadius: coverWidth * cover.screenCorner
        )
    }

    /// Devices hidden: both screens float in the screen's room, at the
    /// same scale, side by side and centered.
    func placeFloatingPair(in layout: inout ScreenshotLayout, companion: PixelSize) {
        let room = layout.screen
        let width = layout.canvas.width
        let height = layout.canvas.height
        let pairGap = Self.pairGap * width
        let coverWidth = CGFloat(companion.width)
        let coverHeight = CGFloat(companion.height)
        let scale = max(0, min((room.width - pairGap) / (width + coverWidth), room.height / max(height, coverHeight, 1)))
        let innerSize = CGSize(width: width * scale, height: height * scale)
        let coverSize = CGSize(width: coverWidth * scale, height: coverHeight * scale)
        let left = room.minX + (room.width - innerSize.width - pairGap - coverSize.width) / 2
        var innerRect = CGRect(origin: CGPoint(x: left, y: room.minY), size: innerSize)
        var coverRect = CGRect(origin: CGPoint(x: left + innerSize.width + pairGap, y: room.minY), size: coverSize)
        if layout.isMirrored {
            coverRect.origin.x = left
            innerRect.origin.x = left + coverSize.width + pairGap
        }
        layout.screen = innerRect
        layout.screenCornerRadius = 0.05 * innerSize.width
        layout.companion = LayoutCompanion(device: nil, screen: coverRect, screenCornerRadius: 0.1 * coverSize.width)
    }
}
