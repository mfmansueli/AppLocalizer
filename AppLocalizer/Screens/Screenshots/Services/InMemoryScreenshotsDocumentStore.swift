//
//  InMemoryScreenshotsDocumentStore.swift
//  AppLocalizer
//

import Foundation

/// A document store that forgets on quit, for tests and DEBUG scenes.
@MainActor
final class InMemoryScreenshotsDocumentStore: ScreenshotsDocumentStore {
    private(set) var documents: [String: ScreenshotsDocument]
    private(set) var saveCount = 0

    init(documents: [String: ScreenshotsDocument] = [:]) {
        self.documents = documents
    }

    func load(appID: String) throws -> ScreenshotsDocument? {
        documents[appID]
    }

    func save(_ document: ScreenshotsDocument, appID: String) throws {
        documents[appID] = document
        saveCount += 1
    }
}
