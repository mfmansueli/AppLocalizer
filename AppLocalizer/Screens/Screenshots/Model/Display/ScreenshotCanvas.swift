//
//  ScreenshotCanvas.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The exact output a render has for one display type and orientation:
/// Apple's pixel size, and the unit `u` the template's sizes are in
/// (short side ÷ 1320). A 112 u headline is 112 px on a 1320 × 2868 iPhone
/// canvas and 175 px on a 2752 × 2064 iPad canvas. Every iPhone Duo
/// screenshot is Apple's 2007 × 2853, either way up; a closed one frames
/// the cover display inside it (`isCoverDisplay`).
struct ScreenshotCanvas: Hashable, Sendable {
    let display: ScreenshotDisplayType
    let orientation: ScreenshotOrientation
    /// iPhone Duo closed: the folded phone, its cover display's shape
    /// (1398 × 2034), placed on the 2007 × 2853 canvas.
    var isCoverDisplay = false

    var pixelSize: PixelSize {
        let portrait = display.portraitPixelSize
        return orientation == .portrait ? portrait : portrait.rotated
    }

    var width: CGFloat { CGFloat(pixelSize.width) }
    var height: CGFloat { CGFloat(pixelSize.height) }
    var size: CGSize { pixelSize.cgSize }
    var isLandscape: Bool { orientation == .landscape }

    /// One u in pixels.
    var unit: CGFloat { min(width, height) / 1320 }
}
