//
//  ScreenshotChecker.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Runs the checks of README §5 on a laid-out render, in the order the
/// viewer lists them: size and format, glyphs, fit, capture size, UI not
/// localized, then what's missing.
enum ScreenshotChecker {
    /// How far a capture may be cropped or scaled before it fails.
    static let tolerance = 0.10

    static func checks(for layout: ScreenshotLayout, capture: ResolvedCapture?, primaryLocaleName: String) -> [RenderCheck] {
        let canvas = layout.canvas
        var checks = [RenderCheck(
            kind: .sizeAndFormat, status: .passed,
            text: String(localized: "PNG · \(canvas.pixelSize.title) px · RGB, no transparency")
        )]
        let hasCaption = !layout.headline.isEmpty
        if let glyphs = glyphCheck(layout) { checks.append(glyphs) }
        checks.append(hasCaption ? fitCheck(layout) : RenderCheck(
            kind: .captionPresent, status: .pending, text: String(localized: "No caption yet"), shortReason: String(localized: "No caption")
        ))
        if let capture {
            if let size = captureSizeCheck(capture.capture, layout: layout) { checks.append(size) }
            if !capture.isInterfaceLocalized {
                checks.append(RenderCheck(
                    kind: .interfaceLocalized, status: .warning,
                    text: String(localized: "UI not localized: this capture shows the \(primaryLocaleName) interface"),
                    shortReason: String(localized: "UI not localized")
                ))
            }
        } else {
            checks.append(RenderCheck(
                kind: .capturePresent, status: .pending, text: String(localized: "No capture for this slot"), shortReason: String(localized: "No capture")
            ))
        }
        return checks
    }

    /// The first check that blocks the push.
    static func firstFailure(in checks: [RenderCheck]) -> RenderCheck? {
        checks.first(where: \.blocksPush)
    }

    private static func glyphCheck(_ layout: ScreenshotLayout) -> RenderCheck? {
        guard !layout.headline.isEmpty else { return nil }
        let choices = [layout.headlineFont] + (layout.subhead?.isEmpty == false ? [layout.subheadFont].compactMap(\.self) : [])
        if let problem = choices.lazy.compactMap(\.problem).first {
            return RenderCheck(kind: .glyphs, status: .failed, text: problem, shortReason: String(localized: "Missing glyphs"))
        }
        return RenderCheck(
            kind: .glyphs, status: .passed,
            text: String(localized: "Every character has a glyph · \(layout.headlineFont.fontName)")
        )
    }

    private static func fitCheck(_ layout: ScreenshotLayout) -> RenderCheck {
        let overflow = String(localized: "Overflow")
        if !layout.headline.fits {
            return RenderCheck(kind: .fit, status: .failed, text: String(localized: "Headline overflows: \(layout.headline.label)"), shortReason: overflow)
        }
        if let subhead = layout.subhead, !subhead.fits {
            return RenderCheck(kind: .fit, status: .failed, text: String(localized: "Subhead overflows: \(subhead.label)"), shortReason: overflow)
        }
        return RenderCheck(kind: .fit, status: .passed, text: layout.headline.summary)
    }

    /// Fails for a capture from the other device class, or one that would
    /// be cropped (or, full-bleed, scaled) by more than 10%.
    static func captureSizeCheck(_ capture: ScreenshotCapture, layout: ScreenshotLayout) -> RenderCheck? {
        let display = layout.canvas.display
        let wrongSize = String(localized: "Wrong size")
        let size = capture.pixelSize
        let isTabletCapture = size.aspectRatio < 1.7
        if isTabletCapture != display.isTablet {
            let kind = isTabletCapture ? String(localized: "an iPad screenshot") : String(localized: "an iPhone screenshot")
            let text = String(localized: "Wrong size: the capture is \(size.title), \(kind). Retake it on an \(display.deviceName) simulator.")
            return RenderCheck(kind: .captureSize, status: .failed, text: text, shortReason: wrongSize)
        }
        let frame = layout.captureFrame(for: size)
        let visible = layout.screen.width * layout.screen.height
        let cropped = frame.width * frame.height > 0 ? 1 - visible / (frame.width * frame.height) : 0
        let scaled = layout.isFullBleed ? abs(frame.width / CGFloat(size.width) - 1) : 0
        guard cropped > tolerance || scaled > tolerance else { return nil }
        let percent = Int((max(cropped, scaled) * 100).rounded())
        let text = cropped > tolerance
            ? String(localized: "Wrong size: the capture is \(size.title); it would be cropped by \(percent)%.")
            : String(localized: "Wrong size: the capture is \(size.title); it would be scaled by \(percent)%.")
        return RenderCheck(kind: .captureSize, status: .failed, text: text, shortReason: wrongSize)
    }
}
