//
//  MockLumenCaptureRenderer.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import SwiftUI

/// Draws the sample app's mock captures at the size a render asks for,
/// remembering the last few dozen. A capture recorded as an iPad screenshot
/// draws the iPad layout even in an iPhone slot, as a real wrong-size file
/// would; Apple Watch captures draw LumenWatch.
@MainActor
final class MockLumenCaptureRenderer {
    private var cache: [String: CGImage] = [:]
    private var recent: [String] = []
    private let limit = 80

    func image(for capture: ScreenshotCapture, pixelWidth: Int) -> CGImage? {
        let key = "\(capture.id)@\(pixelWidth)"
        if let image = cache[key] { return image }
        guard let image = render(capture, pixelWidth: pixelWidth) else { return nil }
        cache[key] = image
        recent.append(key)
        if recent.count > limit { cache[recent.removeFirst()] = nil }
        return image
    }

    /// LumenWatch on Apple Watch; the iPad layout for iPad and Apple Vision
    /// Pro windows; the iPhone layout otherwise.
    private func render(_ capture: ScreenshotCapture, pixelWidth: Int) -> CGImage? {
        let width = CGFloat(min(pixelWidth, capture.pixelSize.width))
        if capture.displayType == .watch {
            let screen = MockLumenWatchScreen(kind: MockLumenWatchKind(slot: capture.slot), locale: capture.locale)
            let renderer = ImageRenderer(content: screen)
            renderer.scale = max(0.1, width / MockLumenWatchScreen.logicalSize.width)
            renderer.isOpaque = true
            return renderer.cgImage
        }
        let isTablet = capture.pixelSize.aspectRatio < 1.7
        let logical = MockLumenScreen.logicalSize(isTablet: isTablet)
        let screen = MockLumenScreen(kind: MockLumenScreenKind(slot: capture.slot), locale: capture.locale, isTablet: isTablet)
        let renderer = ImageRenderer(content: screen)
        renderer.scale = max(0.1, width / logical.width)
        renderer.isOpaque = true
        return renderer.cgImage
    }
}
#endif
