//
//  FileMachineTranslationStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps machine-translation tags as JSON in Application Support
/// (`MachineTranslations.json`), so "machine-translated, not reviewed"
/// survives relaunching. Read once, written on every change.
@MainActor
final class FileMachineTranslationStore: MachineTranslationStore {
    static let shared = FileMachineTranslationStore()

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "MachineTranslations.json")
    }

    private let url: URL
    private var storage: [String: [String: String]]

    init(url: URL = FileMachineTranslationStore.defaultURL) {
        self.url = url
        let data = try? Data(contentsOf: url)
        storage = data.flatMap { try? JSONDecoder().decode([String: [String: String]].self, from: $0) } ?? [:]
    }

    func tags(appID: StoreApp.ID, scope: String) -> [String: String] {
        storage[InMemoryMachineTranslationStore.key(appID, scope)] ?? [:]
    }

    func setTags(_ tags: [String: String], appID: StoreApp.ID, scope: String) {
        let key = InMemoryMachineTranslationStore.key(appID, scope)
        let value = tags.isEmpty ? nil : tags
        guard storage[key] != value else { return }
        storage[key] = value
        save()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            try encoder.encode(storage).write(to: url, options: .atomic)
        } catch {
            // Losing a tag only means a text no longer reads as unreviewed;
            // the edits themselves are in the change queue.
        }
    }
}
