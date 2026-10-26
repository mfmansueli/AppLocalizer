//
//  AppInformationNotesStore.swift
//  AppLocalizer
//

import Foundation

/// Where `AppInformationNotes` are kept: `DefaultsAppInformationNotesStore`
/// on this Mac, `InMemoryAppInformationNotesStore` in tests and DEBUG.
@MainActor
protocol AppInformationNotesStore: AnyObject {
    func notes(for appID: StoreApp.ID) -> AppInformationNotes
    func setNotes(_ notes: AppInformationNotes, for appID: StoreApp.ID)
}
