//
//  FieldSuggestionStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The store every suggestion lives in: adding, what a field shows,
/// built-in checks rerunning, decisions and their undo, and an Ask
/// request counting what arrives.
@MainActor
@Suite("FieldSuggestionStore")
struct FieldSuggestionStoreTests {
    private let clock = TestClock()
    private let appID = "6450000001"
    private let whatsNew = SuggestionTarget.storePage(.englishUS, .whatsNew)
    private let claude = SuggestionSource.assistant(client: "Claude Code")

    private func store() -> FieldSuggestionStore {
        FieldSuggestionStore(now: { [clock] in clock.now })
    }

    @Test func addingQueuesThenReplacesTheSameSourcesOpenSuggestion() {
        let store = store()
        let first = store.add(appID: appID, target: whatsNew, value: "• Weekly reflections", reason: "From commits.", source: claude)
        #expect(first.outcome == .queued)
        #expect(first.suggestion.id == "sg_1")

        let again = store.add(appID: appID, target: whatsNew, value: "• Weekly reflections", reason: "From commits.", source: claude)
        #expect(again.outcome == .unchanged)
        #expect(again.suggestion.id == first.suggestion.id)

        let newer = store.add(appID: appID, target: whatsNew, value: "• Weekly reflections\n• Faster search", reason: "", source: claude)
        #expect(newer.outcome == .replaced)
        #expect(store.all(for: appID).map(\.id) == [newer.suggestion.id])
    }

    @Test func aFieldShowsTheNewestOpenSuggestionUnlessItHoldsIt() {
        let store = store()
        store.add(appID: appID, target: whatsNew, value: "Provider text", reason: "", source: .aiProvider)
        clock.advance(by: 60)
        let newest = store.add(appID: appID, target: whatsNew, value: "Claude text", reason: "", source: claude).suggestion

        #expect(store.shown(for: whatsNew, appID: appID, currentValue: "Old")?.id == newest.id)
        #expect(store.shown(for: whatsNew, appID: appID, currentValue: "Old", filter: .aiProvider)?.value == "Provider text")
        #expect(store.shown(for: whatsNew, appID: appID, currentValue: "Claude text")?.value == "Provider text")

        store.dismiss([newest.id])
        #expect(store.shown(for: whatsNew, appID: appID, currentValue: "Old")?.value == "Provider text")
        store.restore([newest.id])
        #expect(store.shown(for: whatsNew, appID: appID, currentValue: "Old")?.id == newest.id)
    }

    @Test func builtInChecksReplaceTheirOwnAndKeepDecisions() {
        let store = store()
        let copyright = SuggestionTarget.appInformation(.copyright)
        let found = FieldSuggestion.builtIn(appID: appID, target: copyright, value: "© 2026 Northpier", reason: "Year.")
        store.add(appID: appID, target: whatsNew, value: "Claude text", reason: "", source: claude)
        store.setBuiltIn([found], appID: appID, scopes: [.appInformation(.general)])
        store.dismiss([found.id])
        clock.advance(by: 60)

        // The same finding again: the same id, still dismissed, its first date kept.
        let again = FieldSuggestion.builtIn(appID: appID, target: copyright, value: "© 2026 Northpier", reason: "Year.")
        store.setBuiltIn([again], appID: appID, scopes: [.appInformation(.general)])
        #expect(store.isDismissed(again))
        #expect(store.suggestion(id: again.id)?.createdAt == found.createdAt)

        // Nothing found any more: the built-in goes, the assistant's stays.
        store.setBuiltIn([], appID: appID, scopes: [.appInformation(.general)])
        #expect(store.all(for: appID).map(\.source) == [claude])
    }

    @Test func acceptingRemembersWhoAndUndoOpensItAgain() throws {
        let store = store()
        let suggestion = store.add(appID: appID, target: whatsNew, value: "New", reason: "", source: claude).suggestion
        store.markAccepted(suggestion, previousValue: "Old")
        #expect(!store.isOpen(suggestion))
        let provenance = try #require(store.provenance(for: whatsNew, appID: appID))
        #expect(provenance.line(currentValue: "New") == "Accepted Claude Code’s suggestion.")
        #expect(provenance.line(currentValue: "Newer") == "Edited from Claude Code’s suggestion.")

        let undone = store.undoAcceptance(of: whatsNew, appID: appID)
        #expect(undone?.previousValue == "Old")
        #expect(store.isOpen(suggestion))
        #expect(store.provenance(for: whatsNew, appID: appID) == nil)
    }

    @Test func useAndEditSaysSoUntilTheTextChanges() {
        let provenance = SuggestionProvenance(suggestionID: "sg_1", source: .builtIn, value: "A", previousValue: "", isForEditing: true)
        #expect(provenance.line(currentValue: "A") == "Using a built-in suggestion. Edit it above.")
        #expect(provenance.line(currentValue: "AB") == "Edited from a built-in suggestion.")
    }

    @Test func provenanceIsForgottenOnceTheValueIsNoLongerPending() {
        let store = store()
        let suggestion = store.add(appID: appID, target: whatsNew, value: "New", reason: "", source: claude).suggestion
        store.markAccepted(suggestion, previousValue: "Old")
        store.pruneProvenance(appID: appID, area: .storePage, keeping: [whatsNew])
        #expect(store.provenance(for: whatsNew, appID: appID) != nil)
        store.pruneProvenance(appID: appID, area: .appInformation, keeping: [])
        #expect(store.provenance(for: whatsNew, appID: appID) != nil)
        store.pruneProvenance(appID: appID, area: .storePage, keeping: [])
        #expect(store.provenance(for: whatsNew, appID: appID) == nil)
    }

    @Test func restoringTheReviewPutsEveryDecisionBack() {
        let store = store()
        let one = store.add(appID: appID, target: whatsNew, value: "One", reason: "", source: claude).suggestion
        let before = store.review
        store.markAccepted(one, previousValue: "")
        store.restoreReview(before)
        #expect(store.isOpen(one))
        #expect(store.provenance(for: whatsNew, appID: appID) == nil)
    }

    @Test func anAskRequestCountsTheAssistantsSuggestionsForThatApp() throws {
        let store = store()
        store.beginRequest(appID: appID, area: .storePage, client: "Claude Code", prompt: "Suggest…")
        store.noteExpectedTotal(2, client: "Claude Code", appID: appID)
        store.add(appID: "other", target: whatsNew, value: "Elsewhere", reason: "", source: claude)
        store.add(appID: appID, target: whatsNew, value: "From the provider", reason: "", source: .aiProvider)
        #expect(store.request?.isReceiving == false)

        store.add(appID: appID, target: whatsNew, value: "One", reason: "", source: claude)
        let request = try #require(store.request)
        #expect(request.isReceiving)
        #expect(request.progressText == "Sending suggestions · 1 of 2")
        #expect(request.fraction == 0.5)
        #expect(!request.isComplete)

        store.add(appID: appID, target: .storePage(.german, .whatsNew), value: "Zwei", reason: "", source: claude)
        #expect(store.request?.isComplete == true)
        let finished = store.finishRequest()
        #expect(finished?.finishedText == "Claude Code sent 2 suggestions. Nothing changes until you accept them.")
        #expect(store.request == nil)
    }

    @Test func cancellingAnAskForgetsIt() {
        let store = store()
        store.beginRequest(appID: appID, area: .appInformation, client: "Cursor", prompt: "Suggest…")
        store.cancelRequest()
        #expect(store.request == nil)
    }
}
