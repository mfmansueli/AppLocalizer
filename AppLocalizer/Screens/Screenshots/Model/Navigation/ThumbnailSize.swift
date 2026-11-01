//
//  ThumbnailSize.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The Sets thumbnails' size. M shows a caption you can judge.
enum ThumbnailSize: String, CaseIterable, Identifiable, Hashable, Sendable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: String(localized: "S")
        case .medium: String(localized: "M")
        case .large: String(localized: "L")
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .small: String(localized: "Small thumbnails")
        case .medium: String(localized: "Medium thumbnails")
        case .large: String(localized: "Large thumbnails")
        }
    }

    /// The thumbnail width in points: 44 / 64 / 92 for iPhone and Apple
    /// Watch, 84 / 116 / 164 for iPad and Apple Vision Pro, iPhone Duo's at
    /// the iPhone's height.
    func width(for display: ScreenshotDisplayType) -> CGFloat {
        if display == .iPhoneDuo { return display.thumbnailWidth(phone: width(for: .iPhone), tablet: 0) }
        return switch (self, display.isTablet || display == .visionPro) {
        case (.small, false): 44
        case (.medium, false): 64
        case (.large, false): 92
        case (.small, true): 84
        case (.medium, true): 116
        case (.large, true): 164
        }
    }

    /// Thumbnails are rendered once at twice the largest size and scaled
    /// down for the others.
    static func renderPixelWidth(for display: ScreenshotDisplayType) -> Int {
        Int(ThumbnailSize.large.width(for: display) * 2)
    }
}
