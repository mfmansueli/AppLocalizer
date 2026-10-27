//
//  ScreenshotRestoreRequest.swift
//  AppLocalizer
//

import Foundation

/// A locale's kept screenshots queued by Restore Previous Screenshots…:
/// they go back through Review & Push like any other images. The request
/// lasts until they're pushed, or until the locale goes back to the
/// template (Use Template Again unpins it).
struct ScreenshotRestoreRequest: Codable, Hashable, Sendable, Identifiable {
    var locale: String
    var backupID: String
    /// When the screenshots were kept: "Restore from Oct 12".
    var backupDate: Date
    var images: [ScreenshotBackupImage]

    var id: String { "\(locale)|\(backupID)" }
}
