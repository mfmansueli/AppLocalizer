//
//  AppPreviewSpec.swift
//  AppLocalizer
//

import Foundation

/// Apple's rules for one device's App Preview: its exact size, at most 30
/// frames a second, 15 to 30 seconds long (AppLocalizer aims for 24), at
/// most 500 MB, and the poster frame App Store Connect shows before it
/// plays.
struct AppPreviewSpec: Hashable, Sendable {
    var displayType: ScreenshotDisplayType
    var pixelSize: PixelSize
    var framesPerSecond = 30
    /// The length AppLocalizer cuts to.
    var targetSeconds = 24.0
    var minimumSeconds = 15.0
    var maximumSeconds = 30.0
    /// Where the poster frame is taken.
    var posterSeconds = 5.0
    var maximumBytes: Int64 = 500 * 1024 * 1024

    /// The devices an App Preview is made for.
    static let displayTypes: [ScreenshotDisplayType] = [.iPhone, .iPad]

    /// iPhone 6.9″ takes 886 × 1920 (1920 × 886 on its side); iPad 13″
    /// 1200 × 1600 (1600 × 1200), an assumption to check on Apple's
    /// specifications page. Nil for every other device.
    static func spec(for display: ScreenshotDisplayType, landscape: Bool) -> AppPreviewSpec? {
        let portrait: PixelSize
        switch display {
        case .iPhone: portrait = PixelSize(width: 886, height: 1920)
        case .iPad: portrait = PixelSize(width: 1200, height: 1600)
        default: return nil
        }
        return AppPreviewSpec(displayType: display, pixelSize: landscape ? portrait.rotated : portrait)
    }

    var isLandscape: Bool { pixelSize.isLandscape }

    /// The poster frame's time code, HH:MM:SS:FF: "00:00:05:00".
    var posterTimeCode: String {
        let frames = Int((posterSeconds * Double(framesPerSecond)).rounded())
        let fps = max(framesPerSecond, 1)
        let seconds = frames / fps
        return String(format: "%02d:%02d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60, frames % fps)
    }

    /// One frame's length in seconds.
    var frameSeconds: Double { 1 / Double(max(framesPerSecond, 1)) }
}
