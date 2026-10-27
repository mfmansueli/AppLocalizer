//
//  ScreenshotBackup.swift
//  AppLocalizer
//

import Foundation

/// Everything one screenshot push replaced, kept in
/// `Application Support/AppLocalizer/Backups/<app>/<date>/`. Restore
/// Previous Screenshots… puts a locale's kept set back through review.
struct ScreenshotBackup: Codable, Hashable, Sendable, Identifiable {
    /// The folder name, from the push's date: `2026-10-12-143205`.
    var id: String
    var appID: String
    /// When the push ran.
    var date: Date
    var images: [ScreenshotBackupImage]

    /// The backup ID for a push that started at `date`.
    static func id(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: date)
    }

    /// A locale's kept screenshots on one display type, in set order.
    func images(locale: String, displayType: ScreenshotDisplayType) -> [ScreenshotBackupImage] {
        images.filter { $0.locale == locale && $0.displayType == displayType }.sorted { $0.position < $1.position }
    }

    /// A locale's kept screenshots on every display type.
    func images(locale: String) -> [ScreenshotBackupImage] {
        ScreenshotDisplayType.allCases.flatMap { images(locale: locale, displayType: $0) }
    }

    /// The locales anything was kept for, in the order they were kept.
    var locales: [String] {
        var seen: Set<String> = []
        return images.map(\.locale).filter { seen.insert($0).inserted }
    }

    /// Adds `image`, replacing one kept for the same position.
    mutating func add(_ image: ScreenshotBackupImage) {
        images.removeAll { $0.id == image.id }
        images.append(image)
    }
}
