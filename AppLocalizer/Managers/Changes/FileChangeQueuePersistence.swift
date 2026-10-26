//
//  FileChangeQueuePersistence.swift
//  AppLocalizer
//

import Foundation

/// Keeps pending changes as JSON in Application Support
/// (`PendingChanges.json`). The file holds request bodies, never the key.
struct FileChangeQueuePersistence: ChangeQueuePersistence {
    var url: URL = Self.defaultURL

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "PendingChanges.json")
    }

    func load() throws -> [PendingChange] {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PendingChange].self, from: Data(contentsOf: url))
    }

    func save(_ changes: [PendingChange]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(changes).write(to: url, options: .atomic)
    }
}
