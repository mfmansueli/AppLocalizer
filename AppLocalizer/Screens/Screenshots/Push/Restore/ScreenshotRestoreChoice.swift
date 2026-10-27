//
//  ScreenshotRestoreChoice.swift
//  AppLocalizer
//

import Foundation

/// One locale in Restore Previous Screenshots…: what was kept for it, or
/// that it had no screenshots of its own then.
struct ScreenshotRestoreChoice: Identifiable, Hashable, Sendable {
    var locale: StoreLocale
    var images: [ScreenshotBackupImage]
    /// "English (U.S.)", for "Had none · used English (U.S.)".
    var primaryLocaleName: String

    var id: String { locale.code }

    var hasImages: Bool { !images.isEmpty }

    func images(on display: ScreenshotDisplayType) -> [ScreenshotBackupImage] {
        images.filter { $0.displayType == display }.sorted { $0.position < $1.position }
    }

    /// "5 + 5 screenshots · uploaded by hand", "Had none · used English
    /// (U.S.)".
    var note: String {
        guard let first = images.first else { return String(localized: "Had none · used \(primaryLocaleName)") }
        let counts = ScreenshotDisplayType.rendered.map { images(on: $0).count }.filter { $0 > 0 }
        let count = counts.map(String.init).joined(separator: " + ")
        let screenshots = counts == [1] ? String(localized: "\(count) screenshot") : String(localized: "\(count) screenshots")
        return "\(screenshots) · \(first.origin.title)"
    }

    /// The choices for one push: locales with kept screenshots first, then
    /// those that had none, each in push order.
    static func choices(for summary: ScreenshotPushSummary, backup: ScreenshotBackup?, primaryLocaleName: String) -> [ScreenshotRestoreChoice] {
        let all = summary.locales.compactMap { code in
            StoreLocaleCatalog.locale(code: code).map { locale in
                ScreenshotRestoreChoice(locale: locale, images: backup?.images(locale: code) ?? [], primaryLocaleName: primaryLocaleName)
            }
        }
        return all.filter(\.hasImages) + all.filter { !$0.hasImages }
    }
}
