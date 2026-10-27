//
//  FileScreenshotsDocumentStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps each app's screenshot document as
/// `Application Support/AppLocalizer/Screenshots/<appID>/document.json`.
/// Captures and kept sets live next to it.
struct FileScreenshotsDocumentStore: ScreenshotsDocumentStore {
    var root: URL = Self.defaultRoot

    static var defaultRoot: URL {
        URL.applicationSupportDirectory.appending(path: "AppLocalizer/Screenshots", directoryHint: .isDirectory)
    }

    /// The app's folder.
    func directory(appID: String) -> URL {
        root.appending(path: appID, directoryHint: .isDirectory)
    }

    func load(appID: String) throws -> ScreenshotsDocument? {
        let url = directory(appID: appID).appending(path: "document.json")
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ScreenshotsDocument.self, from: Data(contentsOf: url))
    }

    func save(_ document: ScreenshotsDocument, appID: String) throws {
        let folder = directory(appID: appID)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(document).write(to: folder.appending(path: "document.json"), options: .atomic)
    }
}
