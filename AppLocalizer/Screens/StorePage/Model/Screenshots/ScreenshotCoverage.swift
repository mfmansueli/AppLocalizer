//
//  ScreenshotCoverage.swift
//  AppLocalizer
//

import Foundation

/// The read-only Screenshots view: how many screenshots each locale has
/// per device size. A locale without iPhone screenshots falls back to the
/// primary locale's; other sizes without any are flagged missing.
struct ScreenshotCoverage: Hashable, Sendable {
    let primaryLocale: StoreLocale
    let counts: [StoreLocale: [ScreenshotDevice: Int]]

    func count(for locale: StoreLocale, on device: ScreenshotDevice) -> Int {
        counts[locale]?[device] ?? 0
    }

    func status(for locale: StoreLocale, on device: ScreenshotDevice) -> ScreenshotStatus {
        let count = count(for: locale, on: device)
        if count > 0 { return .present(count: count) }
        if device == .iPhone, locale != primaryLocale, self.count(for: primaryLocale, on: .iPhone) > 0 {
            return .usesPrimary(primaryLocale)
        }
        return .missing
    }

    /// Flagged cells across the given locales.
    func flaggedCount(in locales: [StoreLocale]) -> Int {
        locales.reduce(0) { total, locale in
            total + ScreenshotDevice.allCases.count(where: { status(for: locale, on: $0).isFlagged })
        }
    }
}
