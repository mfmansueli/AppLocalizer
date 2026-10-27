//
//  InMemoryMachineTranslationStore.swift
//  AppLocalizer
//

import Foundation

/// A `MachineTranslationStore` that forgets everything on quit: tests and
/// DEBUG scenes.
@MainActor
final class InMemoryMachineTranslationStore: MachineTranslationStore {
    private var storage: [String: [String: String]]

    /// `storage` is keyed by `"<appID>/<scope>"`.
    init(storage: [String: [String: String]] = [:]) {
        self.storage = storage
    }

    func tags(appID: StoreApp.ID, scope: String) -> [String: String] {
        storage[Self.key(appID, scope)] ?? [:]
    }

    func setTags(_ tags: [String: String], appID: StoreApp.ID, scope: String) {
        storage[Self.key(appID, scope)] = tags.isEmpty ? nil : tags
    }

    nonisolated static func key(_ appID: StoreApp.ID, _ scope: String) -> String {
        "\(appID)/\(scope)"
    }
}
