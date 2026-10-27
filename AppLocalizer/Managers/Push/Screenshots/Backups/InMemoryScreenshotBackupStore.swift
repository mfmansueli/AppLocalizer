//
//  InMemoryScreenshotBackupStore.swift
//  AppLocalizer
//

import Foundation

/// A backup store that forgets on quit, for tests and DEBUG scenes.
@MainActor
final class InMemoryScreenshotBackupStore: ScreenshotBackupStore {
    private(set) var backups: [String: ScreenshotBackup] = [:]
    private(set) var files: [String: Data] = [:]

    init() {}

    func keep(_ data: Data, as image: ScreenshotBackupImage, appID: String, date: Date) throws {
        let key = "\(appID)|\(image.backupID)"
        var backup = backups[key] ?? ScreenshotBackup(id: image.backupID, appID: appID, date: date, images: [])
        backup.add(image)
        backups[key] = backup
        files["\(appID)|\(image.id)"] = data
    }

    func backup(id: String, appID: String) -> ScreenshotBackup? {
        backups["\(appID)|\(id)"]
    }

    func data(for image: ScreenshotBackupImage, appID: String) throws -> Data {
        guard let data = files["\(appID)|\(image.id)"] else { throw CocoaError(.fileNoSuchFile) }
        return data
    }
}
