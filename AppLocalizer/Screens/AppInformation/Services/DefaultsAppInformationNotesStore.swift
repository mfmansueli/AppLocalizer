//
//  DefaultsAppInformationNotesStore.swift
//  AppLocalizer
//

import Foundation

/// Keeps `AppInformationNotes` in the user defaults, as JSON per app. They
/// hold no secrets: the demo password is in the Keychain.
@MainActor
final class DefaultsAppInformationNotesStore: AppInformationNotesStore {
    static let shared = DefaultsAppInformationNotesStore()

    private let defaults: UserDefaults
    private let keyPrefix = "AppInformationNotes."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func notes(for appID: StoreApp.ID) -> AppInformationNotes {
        guard let data = defaults.data(forKey: keyPrefix + appID),
              let notes = try? JSONDecoder().decode(AppInformationNotes.self, from: data)
        else { return AppInformationNotes() }
        return notes
    }

    func setNotes(_ notes: AppInformationNotes, for appID: StoreApp.ID) {
        defaults.set(try? JSONEncoder().encode(notes), forKey: keyPrefix + appID)
    }
}
