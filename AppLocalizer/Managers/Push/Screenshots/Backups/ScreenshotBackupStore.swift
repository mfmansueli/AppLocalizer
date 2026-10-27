//
//  ScreenshotBackupStore.swift
//  AppLocalizer
//

import Foundation

/// Where replaced screenshots are kept before a push deletes them: files
/// in Application Support (`FileScreenshotBackupStore`), or memory for
/// tests and DEBUG scenes (`InMemoryScreenshotBackupStore`).
@MainActor
protocol ScreenshotBackupStore {
    /// Keeps `data` as `image`, in the backup of the push that started at
    /// `date` (created on first use).
    func keep(_ data: Data, as image: ScreenshotBackupImage, appID: String, date: Date) throws

    /// One push's backup, or nil when nothing was kept.
    func backup(id: String, appID: String) -> ScreenshotBackup?

    /// The file a kept screenshot was saved as.
    func data(for image: ScreenshotBackupImage, appID: String) throws -> Data
}
