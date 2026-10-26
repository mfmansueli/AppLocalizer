//
//  ScreenshotsDocumentStore.swift
//  AppLocalizer
//

import Foundation

/// Where an app's `ScreenshotsDocument` is kept: a JSON file per app in
/// Application Support, or memory for tests and DEBUG scenes.
@MainActor
protocol ScreenshotsDocumentStore {
    /// The saved document, or nil when there's none yet.
    func load(appID: String) throws -> ScreenshotsDocument?
    func save(_ document: ScreenshotsDocument, appID: String) throws
}
