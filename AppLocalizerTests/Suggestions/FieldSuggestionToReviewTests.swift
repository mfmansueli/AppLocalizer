//
//  FieldSuggestionToReviewTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What counts as left to review: only what a section really shows, one
/// per field, kept between launches.
@MainActor
@Suite("FieldSuggestionStore to review")
struct FieldSuggestionToReviewTests {
    private let clock = TestClock()
    private let appID = "6450000001"
    private let whatsNew = SuggestionTarget.storePage(.englishUS, .whatsNew)
    private let support = SuggestionTarget.storePage(.englishUS, .supportURL)
    private let claude = SuggestionSource.assistant(client: "Claude Code")

    private func store(persistence: (any FieldSuggestionPersistence)? = nil) -> FieldSuggestionStore {
        FieldSuggestionStore(persistence: persistence, now: { [clock] in clock.now })
    }

    @discardableResult
    private func add(_ target: SuggestionTarget, _ value: String, source: SuggestionSource? = nil, to store: FieldSuggestionStore) -> FieldSuggestion {
        store.add(appID: appID, target: target, value: value, reason: "", source: source ?? claude).suggestion
    }

    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).json")
    }

    @Test func whatTheSectionHidesIsntCounted() {
        let store = store()
        let shown = add(whatsNew, "• New", to: store)
        add(support, "https://already.there", to: store)
        #expect(store.toReview(for: appID).count == 2)

        store.noteShown([shown], appID: appID, area: .storePage)
        #expect(store.toReview(for: appID, area: .storePage).map(\.id) == [shown.id])
    }

    @Test func aHiddenSuggestionComesBackWhenTheSectionShowsIt() {
        let store = store()
        let url = add(support, "https://new.example", to: store)
        store.noteShown([], appID: appID, area: .storePage)
        #expect(store.toReview(for: appID).isEmpty)

        store.noteShown([url], appID: appID, area: .storePage)
        #expect(store.toReview(for: appID).map(\.id) == [url.id])
    }

    @Test func oneFieldCountsOnceWhateverTheSources() {
        let store = store()
        add(whatsNew, "From Claude", to: store)
        clock.advance(by: 1)
        let newest = add(whatsNew, "From the provider", source: .aiProvider, to: store)
        #expect(store.toReview(for: appID).map(\.id) == [newest.id])
    }

    @Test func dismissingTheNewestLeavesTheOlderOneCounted() {
        let store = store()
        let older = add(whatsNew, "From Claude", to: store)
        clock.advance(by: 1)
        let newest = add(whatsNew, "From the provider", source: .aiProvider, to: store)
        store.noteShown([newest], appID: appID, area: .storePage)

        store.dismiss([newest.id])
        #expect(store.toReview(for: appID).map(\.id) == [older.id])
    }

    @Test func aSuggestionThatArrivesAfterTheSectionLookedCounts() {
        let store = store()
        store.noteShown([], appID: appID, area: .storePage)
        let later = add(whatsNew, "• New", to: store)
        #expect(store.toReview(for: appID).map(\.id) == [later.id])
    }

    @Test func oneAreaDoesNotForgetTheOthersHidden() {
        let store = store()
        add(whatsNew, "• New", to: store)
        let copyright = add(.appInformation(.copyright), "© 2026", to: store)
        store.noteShown([], appID: appID, area: .storePage)
        store.noteShown([copyright], appID: appID, area: .appInformation)
        #expect(store.toReview(for: appID).map(\.id) == [copyright.id])
    }

    @Test func whatIsHiddenIsKeptBetweenLaunches() {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let persistence = FileFieldSuggestionPersistence(url: url)
        let first = store(persistence: persistence)
        add(support, "https://already.there", to: first)
        first.noteShown([], appID: appID, area: .storePage)

        let relaunched = store(persistence: persistence)
        #expect(relaunched.persistenceError == nil)
        #expect(relaunched.open(for: appID).count == 1)
        #expect(relaunched.toReview(for: appID).isEmpty)
    }

    /// Files written before `hiddenIDs` existed must keep loading, or every
    /// saved suggestion would be lost.
    @Test func aFileSavedBeforeTheHiddenListStillLoads() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let old = #"{"suggestions":[],"review":{"dismissedIDs":[],"acceptedIDs":[],"provenance":[]},"nextNumber":276}"#
        try Data(old.utf8).write(to: url)

        let store = store(persistence: FileFieldSuggestionPersistence(url: url))
        #expect(store.persistenceError == nil)
        #expect(add(whatsNew, "• New", to: store).id == "sg_276")
    }
}
