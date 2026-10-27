//
//  DefaultsAppInformationNotesStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Keeps `AppInformationNotes` in the user defaults, as JSON per app. They
/// hold no secrets: the demo password is in the Keychain. Observable, so a
/// page showing notes updates when an assistant adds evidence.
@MainActor
@Observable
final class DefaultsAppInformationNotesStore: AppInformationNotesStore {
    static let shared = DefaultsAppInformationNotesStore()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let keyPrefix = "AppInformationNotes."
    /// Bumped on every write, so readers observe changes.
    private var revision = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func notes(for appID: StoreApp.ID) -> AppInformationNotes {
        _ = revision
        guard let data = defaults.data(forKey: keyPrefix + appID),
              let notes = try? JSONDecoder().decode(AppInformationNotes.self, from: data)
        else { return AppInformationNotes() }
        return notes
    }

    func setNotes(_ notes: AppInformationNotes, for appID: StoreApp.ID) {
        defaults.set(try? JSONEncoder().encode(notes), forKey: keyPrefix + appID)
        revision += 1
    }
}
