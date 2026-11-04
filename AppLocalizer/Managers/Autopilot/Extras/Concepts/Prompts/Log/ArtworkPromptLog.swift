//
//  ArtworkPromptLog.swift
//  AppLocalizer
//

import Foundation
import os

/// The prompt log, one JSON object per line (`ArtworkPrompts.jsonl` next to
/// the screenshot documents): every prompt the header and search work
/// used, what came back and how it rendered.
struct ArtworkPromptLog: Sendable {
    var url: URL

    @MainActor static var shared: ArtworkPromptLog { ArtworkPromptLog(url: FileScreenshotsDocumentStore.defaultRoot.appending(path: "ArtworkPrompts.jsonl")) }

    private static let logger = Logger(subsystem: "com.lima.applocalizer", category: "ArtworkPromptLog")

    /// Adds `entry` at the end; a failure is only logged, never in the way.
    func append(_ entry: ArtworkPromptLogEntry) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        do {
            var data = try encoder.encode(entry)
            data.append(0x0A)
            let manager = FileManager.default
            try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !manager.fileExists(atPath: url.path) {
                try data.write(to: url, options: .atomic)
                return
            }
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            Self.logger.error("Couldn’t write the prompt log: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Every entry, oldest first (for tests and tracing).
    func entries() -> [ArtworkPromptLogEntry] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return text.split(separator: "\n").compactMap { try? decoder.decode(ArtworkPromptLogEntry.self, from: Data($0.utf8)) }
    }
}
