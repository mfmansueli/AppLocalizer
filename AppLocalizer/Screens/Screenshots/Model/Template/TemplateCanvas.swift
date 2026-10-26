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

    /// The orientation for `display`; display types the template has no
    /// key for yet are portrait.
    func orientation(for display: ScreenshotDisplayType) -> ScreenshotOrientation {
        switch display {
        case .iPhone: iphone
        case .iPad: ipad
        default: .portrait
        }
    }
}
