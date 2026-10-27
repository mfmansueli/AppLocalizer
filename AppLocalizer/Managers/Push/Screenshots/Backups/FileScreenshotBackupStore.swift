//
//  FileScreenshotBackupStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps replaced screenshots in
/// `Application Support/AppLocalizer/Backups/<appID>/<backupID>/`: one
/// PNG per screenshot (`de-DE/APP_IPHONE_67/3.png`) and a `backup.json`
/// listing them.
struct FileScreenshotBackupStore: ScreenshotBackupStore {
    var root: URL = Self.defaultRoot

    static var defaultRoot: URL {
        URL.applicationSupportDirectory.appending(path: "AppLocalizer/Backups", directoryHint: .isDirectory)
    }

    func directory(backupID: String, appID: String) -> URL {
        root.appending(path: appID, directoryHint: .isDirectory).appending(path: backupID, directoryHint: .isDirectory)
    }

    func keep(_ data: Data, as image: ScreenshotBackupImage, appID: String, date: Date) throws {
        let folder = directory(backupID: image.backupID, appID: appID)
        let file = folder.appending(path: image.relativePath)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: file, options: .atomic)
        var backup = backup(id: image.backupID, appID: appID) ?? ScreenshotBackup(id: image.backupID, appID: appID, date: date, images: [])
        backup.add(image)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(backup).write(to: folder.appending(path: "backup.json"), options: .atomic)
    }

    func backup(id: String, appID: String) -> ScreenshotBackup? {
        let url = directory(backupID: id, appID: appID).appending(path: "backup.json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(ScreenshotBackup.self, from: data)
    }

    func data(for image: ScreenshotBackupImage, appID: String) throws -> Data {
        try Data(contentsOf: directory(backupID: image.backupID, appID: appID).appending(path: image.relativePath))
    }
}
