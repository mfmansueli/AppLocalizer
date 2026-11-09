//
//  RetentionDraftStoreTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The editor's copies last past closing AppLocalizer.
@MainActor
@Suite("RetentionDraftStore")
struct RetentionDraftStoreTests {
    private let url = URL.temporaryDirectory.appending(path: "RetentionDraftStoreTests-\(UUID().uuidString)/RetentionDrafts.json")
    private let appID: StoreApp.ID = "app-1"

    private static let draft = RetentionMessage(
        id: "draft-1", referenceName: "Before you go", texts: ["en-US": RetentionText(header: "Stay", body: "Your entries stay.")]
    )

    @Test func whatsKeptIsThereAfterARelaunch() {
        let store = RetentionDraftStore(url: url)
        store.keep(Self.draft, appID: appID, queued: true)
        store.noteSourceEdited(appID: appID, id: "draft-1")
        store.suggest(RetentionSuggestion(messageID: "draft-1", locale: "de-DE", body: "Kurz.", client: "Claude Code"), appID: appID)
        store.saveNow()

        let relaunched = RetentionDraftStore(url: url)
        #expect(relaunched.message(appID: appID, id: "draft-1") == Self.draft)
        #expect(relaunched.isQueuedCopy(appID: appID, id: "draft-1"))
        #expect(relaunched.isSourceEdited(appID: appID, id: "draft-1"))
        #expect(relaunched.suggestion(appID: appID, messageID: "draft-1", locale: "de-DE")?.body == "Kurz.")
    }

    @Test func removingForgetsTheSourceEdit() {
        let store = RetentionDraftStore(url: url)
        store.keep(Self.draft, appID: appID, queued: false)
        store.noteSourceEdited(appID: appID, id: "draft-1")
        store.remove(appID: appID, id: "draft-1")
        store.saveNow()

        let relaunched = RetentionDraftStore(url: url)
        #expect(relaunched.message(appID: appID, id: "draft-1") == nil)
        #expect(!relaunched.isSourceEdited(appID: appID, id: "draft-1"))
    }

    @Test func resetTakesOnlyThatApp() {
        let store = RetentionDraftStore()
        store.keep(Self.draft, appID: appID, queued: false)
        store.keep(Self.draft, appID: "app-2", queued: false)
        store.noteSourceEdited(appID: appID, id: "draft-1")
        store.reset(appID: appID)
        #expect(store.messages(for: appID).isEmpty)
        #expect(store.messages(for: "app-2").count == 1)
        #expect(!store.isSourceEdited(appID: appID, id: "draft-1"))
    }

    @Test func aDamagedFileStartsEmpty() throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ not json".utf8).write(to: url)
        #expect(RetentionDraftStore(url: url).messages(for: appID).isEmpty)
    }
}
#endif
