//
//  CaptureIndex.swift
//  AppLocalizer
//

import Foundation

/// Every imported capture of an app, keyed by locale × display type × slot.
struct CaptureIndex: Codable, Hashable, Sendable {
    private(set) var captures: [ScreenshotCapture]

    init(captures: [ScreenshotCapture] = []) {
        self.captures = captures
    }

    var isEmpty: Bool { captures.isEmpty }

    /// The capture `locale` has of its own, if any.
    func ownCapture(locale: String, displayType: ScreenshotDisplayType, slot: Int) -> ScreenshotCapture? {
        captures.first { $0.locale == locale && $0.displayType == displayType && $0.slot == slot }
    }

    /// `locale`'s own capture, else the primary locale's.
    func capture(locale: String, displayType: ScreenshotDisplayType, slot: Int, primary: String) -> ResolvedCapture? {
        if let own = ownCapture(locale: locale, displayType: displayType, slot: slot) {
            return ResolvedCapture(capture: own, isInterfaceLocalized: true)
        }
        guard let fallback = ownCapture(locale: primary, displayType: displayType, slot: slot) else { return nil }
        return ResolvedCapture(capture: fallback, isInterfaceLocalized: locale == primary)
    }

    /// Whether `locale` has captures of its own interface on `displayType`
    /// (or on any rendered display type when nil).
    func hasOwnInterface(locale: String, displayType: ScreenshotDisplayType? = nil) -> Bool {
        captures.contains { $0.locale == locale && (displayType == nil || $0.displayType == displayType) }
    }

    /// The locales with captures of their own interface, sorted.
    func localesWithOwnInterface(displayType: ScreenshotDisplayType? = nil) -> [String] {
        Set(captures.filter { displayType == nil || $0.displayType == displayType }.map(\.locale)).sorted()
    }

    mutating func add(_ capture: ScreenshotCapture) {
        captures.removeAll { $0.locale == capture.locale && $0.displayType == capture.displayType && $0.slot == capture.slot }
        captures.append(capture)
    }
}
