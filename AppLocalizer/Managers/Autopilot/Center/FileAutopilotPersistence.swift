//
//  FileAutopilotPersistence.swift
//  AppLocalizer
//

import Foundation

/// Keeps the archive as `Autopilot.json` next to the screenshot documents.
@MainActor
struct FileAutopilotPersistence: AutopilotPersistence {
    var url: URL = FileScreenshotsDocumentStore.defaultRoot.appending(path: "Autopilot.json")

    func load() -> AutopilotArchive {
        guard let data = try? Data(contentsOf: url),
              let archive = try? JSONDecoder().decode(AutopilotArchive.self, from: data) else { return AutopilotArchive() }
        return archive
    }

    func save(_ archive: AutopilotArchive) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            try encoder.encode(archive).write(to: url, options: .atomic)
        } catch {
            NSLog("Autopilot: couldn’t save the runs: \(error.localizedDescription)")
        }
    }
}
