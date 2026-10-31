//
//  FileAppSupportPersistence.swift
//  AppLocalizer
//

import Foundation

/// Keeps the archive as `AppSupport.json` next to the screenshot documents.
@MainActor
struct FileAppSupportPersistence: AppSupportPersistence {
    var url: URL = FileScreenshotsDocumentStore.defaultRoot.appending(path: "AppSupport.json")

    func load() -> AppSupportArchive {
        guard let data = try? Data(contentsOf: url),
              let archive = try? JSONDecoder().decode(AppSupportArchive.self, from: data) else { return AppSupportArchive() }
        return archive
    }

    func save(_ archive: AppSupportArchive) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            try encoder.encode(archive).write(to: url, options: .atomic)
        } catch {
            NSLog("AppSupport: couldn’t save: \(error.localizedDescription)")
        }
    }
}
