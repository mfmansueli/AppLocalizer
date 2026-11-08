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

    /// Whether any capture is of `displayType`.
    func hasCaptures(on displayType: ScreenshotDisplayType) -> Bool {
        captures.contains { $0.displayType == displayType }
    }

    /// The capture `locale` has of its own, if any.
    func ownCapture(locale: String, displayType: ScreenshotDisplayType, slot: Int) -> ScreenshotCapture? {
        captures.first { $0.locale == locale && $0.displayType == displayType && $0.slot == slot && $0.isCompanion != true }
    }

    /// iPhone Duo's cover display beside the slot's inner one: `locale`'s
    /// own, else the primary locale's.
    func companion(locale: String, displayType: ScreenshotDisplayType, slot: Int, primary: String) -> ScreenshotCapture? {
        let find = { (code: String) in
            captures.first { $0.locale == code && $0.displayType == displayType && $0.slot == slot && $0.isCompanion == true }
        }
        return find(locale) ?? find(primary)
    }

    /// Takes every companion off `displayType`: its screenshots show one
    /// display again.
    mutating func removeCompanions(on displayType: ScreenshotDisplayType) {
        captures.removeAll { $0.displayType == displayType && $0.isCompanion == true }
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

    /// Adds a capture in place of the slot's (or its companion's).
    mutating func add(_ capture: ScreenshotCapture) {
        let isCompanion = capture.isCompanion == true
        captures.removeAll {
            $0.locale == capture.locale && $0.displayType == capture.displayType && $0.slot == capture.slot && ($0.isCompanion == true) == isCompanion
        }
        captures.append(capture)
    }
}
