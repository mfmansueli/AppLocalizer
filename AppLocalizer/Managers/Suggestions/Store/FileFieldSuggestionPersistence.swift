//
//  FileFieldSuggestionPersistence.swift
//  AppLocalizer
//

import Foundation

/// Keeps suggestions as JSON in Application Support (`FieldSuggestions.json`).
struct FileFieldSuggestionPersistence: FieldSuggestionPersistence {
    var url: URL = Self.defaultURL

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "FieldSuggestions.json")
    }

    func load() throws -> FieldSuggestionArchive {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return FieldSuggestionArchive() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(FieldSuggestionArchive.self, from: Data(contentsOf: url))
    }

    func save(_ archive: FieldSuggestionArchive) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(archive).write(to: url, options: .atomic)
    }
}
