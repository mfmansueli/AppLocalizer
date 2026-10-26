//
//  FileScreenshotsDocumentStoreTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The document survives a round trip through its JSON file.
@MainActor
@Suite("FileScreenshotsDocumentStore")
struct FileScreenshotsDocumentStoreTests {
    @Test func theSampleDocumentRoundTrips() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ScreenshotsStore-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = FileScreenshotsDocumentStore(root: root)
        #expect(try store.load(appID: "lumen") == nil)
        let document = ScreenshotsDebugDocuments.standard
        try store.save(document, appID: "lumen")
        let loaded = try #require(try store.load(appID: "lumen"))
        #expect(loaded == document)
        #expect(loaded.template?.contentHash == document.template?.contentHash)
    }
}
#endif
