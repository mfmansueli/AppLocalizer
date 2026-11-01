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
