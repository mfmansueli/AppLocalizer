//
//  FileScreenshotPushStateStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps each app's push state as
/// `Application Support/AppLocalizer/Screenshots/<appID>/push-state.json`,
/// next to its screenshot document.
struct FileScreenshotPushStateStore: ScreenshotPushStateStore {
    var root: URL = FileScreenshotsDocumentStore.defaultRoot

    private func url(appID: String) -> URL {
        root.appending(path: appID, directoryHint: .isDirectory).appending(path: "push-state.json")
    }

    func state(appID: String) -> ScreenshotPushState {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: url(appID: appID)),
              let state = try? decoder.decode(ScreenshotPushState.self, from: data) else { return ScreenshotPushState() }
        return state
    }

    func save(_ state: ScreenshotPushState, appID: String) throws {
        let url = url(appID: appID)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(state).write(to: url, options: .atomic)
    }
}
