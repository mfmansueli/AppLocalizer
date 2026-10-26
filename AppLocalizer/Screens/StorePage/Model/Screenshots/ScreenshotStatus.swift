//
//  ScreenshotStatus.swift
//  AppLocalizer
//

import Foundation

/// One cell of the Screenshots view.
enum ScreenshotStatus: Hashable, Sendable {
    case present(count: Int)
    case missing
    /// No iPhone screenshots: the App Store shows the primary locale's.
    case usesPrimary(StoreLocale)

    /// Missing or falling back: flagged in red.
    var isFlagged: Bool {
        if case .present = self { return false }
        return true
    }

    /// "6 screenshots", "Missing" or "Uses English (U.S.)".
    var title: String {
        switch self {
        case let .present(count) where count == 1:
            String(localized: "1 screenshot")
        case let .present(count):
            String(localized: "\(count) screenshots")
        case .missing:
            String(localized: "Missing")
        case let .usesPrimary(locale):
            String(localized: "Uses \(locale.name)")
        }
    }
}
