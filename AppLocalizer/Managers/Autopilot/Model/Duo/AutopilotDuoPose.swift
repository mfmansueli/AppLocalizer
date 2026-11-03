//
//  AutopilotDuoPose.swift
//  AppLocalizer
//

import Foundation

/// How iPhone Duo is held for one of its screenshots. App Store Connect's
/// iPhone Duo set takes both: open, the app on the inner display (2007 ×
/// 2853, which the simulator captures on its side, 2853 × 2007); closed,
/// the app on the cover display (1398 × 2034). The plan's iPhone Duo row
/// says which the set shows.
enum AutopilotDuoPose: String, Codable, Hashable, Sendable, CaseIterable {
    case open
    case closed

    /// "open" or "closed".
    var title: String {
        switch self {
        case .open: String(localized: "open")
        case .closed: String(localized: "closed")
        }
    }

    /// The display the app is on.
    var displayTitle: String {
        switch self {
        case .open: String(localized: "inner display")
        case .closed: String(localized: "cover display")
        }
    }

    /// The capture log's line when iPhone Duo turns this way: "iPhone Duo
    /// folded · launch on the cover display -AppleLanguages (de) …".
    func launchLine(locale: String) -> String {
        let arguments = StoreLocale.simulatorLaunchArguments(for: locale)
        return switch self {
        case .open: String(localized: "iPhone Duo opened in Device Hub · launch on the inner display \(arguments)")
        case .closed: String(localized: "iPhone Duo folded · launch on the cover display \(arguments)")
        }
    }

    /// The display's size in portrait.
    var portraitPixelSize: PixelSize {
        switch self {
        case .open: CaptureSizeRules.duoInnerSize
        case .closed: CaptureSizeRules.duoOuterSize
        }
    }

    /// The pose a capture of this size was taken in; nil for a size that
    /// isn't either display's.
    init?(captureSize size: PixelSize) {
        if CaptureSizeRules.isDuoOuterDisplay(size) {
            self = .closed
        } else if size == CaptureSizeRules.duoInnerSize || size == CaptureSizeRules.duoInnerSize.rotated {
            self = .open
        } else {
            return nil
        }
    }
}
