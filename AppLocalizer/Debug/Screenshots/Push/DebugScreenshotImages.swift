//
//  DebugScreenshotImages.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// Draws the sample screenshots that only exist in App Store Connect: the
/// sets that went live from template v4 on Oct 12, and the hand-uploaded
/// sets that push replaced, in their old look.
@MainActor
final class DebugScreenshotImages {
    let fonts: ScreenshotFontCatalog
    private let captures = MockLumenCaptureRenderer()

    init(fonts: ScreenshotFontCatalog) {
        self.fonts = fonts
    }

    /// One of the sample live screenshots (`live|de-DE|APP_IPHONE_67|2`).
    func liveImage(id: String, pixelWidth: Int) -> CGImage? {
        let parts = id.split(separator: "|").map(String.init)
        guard parts.count == 4, parts[0] == "live", let display = ScreenshotDisplayType(rawValue: parts[2]), let slot = Int(parts[3]),
              let locale = StoreLocaleCatalog.locale(code: parts[1]) else { return nil }
        let data = ScreenshotsSampleData.self
        var caption = data.caption(locale: locale.code, slot: slot, source: data.provenance)
        if locale.code == "de-DE", slot == 2 { caption?.headline = data.liveGermanSearchCaption }
        let layout = ScreenshotLayoutEngine(catalog: fonts).layout(data.template, slot: slot, locale: locale, displayType: display, caption: caption)
        let capture = data.captures.capture(locale: locale.code, displayType: display, slot: slot, primary: data.primary)?.capture
        let image = capture.flatMap { captures.image(for: $0, pixelWidth: pixelWidth) }
        return ScreenshotImageRenderer.image(layout: layout, capture: image, pixelWidth: pixelWidth)
    }

    /// A screenshot uploaded by hand before Oct 12: the plain old look,
    /// with its pixel size.
    func legacyImage(locale code: String, displayType: ScreenshotDisplayType, slot: Int, pixelWidth: Int) -> (CGImage, PixelSize)? {
        guard let locale = StoreLocaleCatalog.locale(code: code) else { return nil }
        let data = ScreenshotsSampleData.self
        let captions = ScreenshotsPushDebugData.legacyCaptions[code] ?? data.legacyCaptions
        let caption = ScreenshotCaption(headline: captions[slot % captions.count])
        let layout = ScreenshotLayoutEngine(catalog: fonts).layout(data.legacyTemplate, slot: slot, locale: locale, displayType: displayType, caption: caption)
        let captured = data.capturedLocales[displayType]?.contains(code) ?? false
        let capture = data.capture(locale: captured ? code : data.primary, display: displayType, slot: slot)
        let image = ScreenshotImageRenderer.image(layout: layout, capture: captures.image(for: capture, pixelWidth: pixelWidth), pixelWidth: pixelWidth)
        return image.map { ($0, layout.canvas.pixelSize) }
    }
}
#endif
