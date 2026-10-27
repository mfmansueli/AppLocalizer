//
//  ResolvedCapture.swift
//  AppLocalizer
//

import Foundation

/// The capture a locale's slot uses: its own, or the primary locale's when
/// it has none, which shows the primary's interface ("UI not localized").
struct ResolvedCapture: Hashable, Sendable {
    var capture: ScreenshotCapture
    /// The capture shows the locale's own interface.
    var isInterfaceLocalized: Bool
}
