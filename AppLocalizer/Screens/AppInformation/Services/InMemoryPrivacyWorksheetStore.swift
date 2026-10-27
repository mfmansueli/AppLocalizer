//
//  InMemoryPrivacyWorksheetStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Worksheets kept in memory, for tests and DEBUG scenes.
@MainActor
@Observable
final class InMemoryPrivacyWorksheetStore: PrivacyWorksheetStore {
    private var storage: [StoreApp.ID: PrivacyWorksheet]

    init(_ storage: [StoreApp.ID: PrivacyWorksheet] = [:]) {
        self.storage = storage
    }

    func worksheet(for appID: StoreApp.ID) -> PrivacyWorksheet {
        storage[appID] ?? PrivacyWorksheet()
    }

    func setWorksheet(_ worksheet: PrivacyWorksheet, for appID: StoreApp.ID) {
        storage[appID] = worksheet
    }
}
