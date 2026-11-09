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
        guard let data = try? Data(contentsOf: url) else { return AutopilotArchive() }
        do {
            return try JSONDecoder().decode(AutopilotArchive.self, from: data)
        } catch {
            keepUnreadable(data, because: error)
            return AutopilotArchive()
        }
    }

    /// The next save replaces the file, so a copy that can't be read stays
    /// beside it: every app's runs are in there.
    private func keepUnreadable(_ data: Data, because error: any Error) {
        let stamp = Int(Date.now.timeIntervalSince1970)
        let copy = url.deletingLastPathComponent().appending(path: "Autopilot-unreadable-\(stamp).json")
        try? data.write(to: copy, options: .atomic)
        NSLog("Autopilot: couldn’t read the runs, kept a copy at \(copy.path): \(error)")
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
