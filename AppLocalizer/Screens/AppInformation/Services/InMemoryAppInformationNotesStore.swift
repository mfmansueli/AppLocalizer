//
//  InMemoryAppInformationNotesStore.swift
//  AppLocalizer
//

import Foundation

/// `AppInformationNotes` kept in memory, for tests and DEBUG scenes.
@MainActor
final class InMemoryAppInformationNotesStore: AppInformationNotesStore {
    private var storage: [StoreApp.ID: AppInformationNotes]

    init(_ storage: [StoreApp.ID: AppInformationNotes] = [:]) {
        self.storage = storage
    }

    func notes(for appID: StoreApp.ID) -> AppInformationNotes {
        storage[appID] ?? AppInformationNotes()
    }

    func setNotes(_ notes: AppInformationNotes, for appID: StoreApp.ID) {
        storage[appID] = notes
    }
}
