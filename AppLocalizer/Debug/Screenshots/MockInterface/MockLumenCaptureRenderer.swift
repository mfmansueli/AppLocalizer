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
/// would.
@MainActor
final class MockLumenCaptureRenderer {
    private var cache: [String: CGImage] = [:]
    private var recent: [String] = []
    private let limit = 80

    func image(for capture: ScreenshotCapture, pixelWidth: Int) -> CGImage? {
        let key = "\(capture.id)@\(pixelWidth)"
        if let image = cache[key] { return image }
        let isTablet = capture.pixelSize.aspectRatio < 1.7
        let logical = MockLumenScreen.logicalSize(isTablet: isTablet)
        let screen = MockLumenScreen(kind: MockLumenScreenKind(slot: capture.slot), locale: capture.locale, isTablet: isTablet)
        let renderer = ImageRenderer(content: screen)
        renderer.scale = max(0.1, CGFloat(min(pixelWidth, capture.pixelSize.width)) / logical.width)
        renderer.isOpaque = true
        guard let image = renderer.cgImage else { return nil }
        cache[key] = image
        recent.append(key)
        if recent.count > limit { cache[recent.removeFirst()] = nil }
        return image
    }
}
#endif
