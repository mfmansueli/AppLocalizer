//
//  TemplateCanvas.swift
//  AppLocalizer
//

import Foundation

/// `canvas`: the orientation per display type. Output is always one of
/// Apple's exact sizes for it (`ScreenshotCanvas`).
struct TemplateCanvas: Codable, Hashable, Sendable {
    var iphone: ScreenshotOrientation
    var ipad: ScreenshotOrientation
    /// iPhone Duo's; templates made before it was added have none and are
    /// portrait there.
    var duo: ScreenshotOrientation?

    /// The orientation for `display`; display types the template has no
    /// key for yet are portrait.
    func orientation(for display: ScreenshotDisplayType) -> ScreenshotOrientation {
        switch display {
        case .iPhone: iphone
        case .iPhoneDuo: duo ?? .portrait
        case .iPad: ipad
        case .visionPro: .landscape
        default: .portrait
        }
    }

    /// The canvas for a capture of `captureSize`: iPhone Duo without an
    /// orientation of its own lies the way its capture does (the
    /// simulator's inner display captures landscape, 2853 × 2007), so the
    /// capture isn't cropped into a Wrong size render. A set orientation,
    /// and every other device's, stays.
    func following(_ captureSize: PixelSize?, on display: ScreenshotDisplayType) -> TemplateCanvas {
        guard display == .iPhoneDuo, duo == nil, captureSize?.isLandscape == true else { return self }
        var canvas = self
        canvas.duo = .landscape
        return canvas
    }

    /// Sets `display`'s orientation; display types without a key of their
    /// own (Apple Vision Pro, Apple Watch) keep theirs.
    mutating func setOrientation(_ orientation: ScreenshotOrientation, for display: ScreenshotDisplayType) {
        switch display {
        case .iPhone: iphone = orientation
        case .iPhoneDuo: duo = orientation
        case .iPad: ipad = orientation
        default: break
        }
    }

    /// The template path of `display`'s orientation: "canvas.iphone",
    /// "canvas.duo" or "canvas.ipad".
    static func path(for display: ScreenshotDisplayType) -> String {
        switch display {
        case .iPad: "canvas.ipad"
        case .iPhoneDuo: "canvas.duo"
        default: "canvas.iphone"
        }
    }
}
