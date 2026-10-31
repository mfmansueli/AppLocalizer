//
//  WorkspaceToastTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The window's toasts for Suggest Everything: the total with Review by
/// Area, Accept All with Undo, and the offer after setup.
@Suite("WorkspaceToast")
struct WorkspaceToastTests {
    private func run(received: Int) -> SuggestionRun {
        var run = SuggestionRun(id: "run_1", appID: "app1", client: "Claude Code", prompt: "", phase: .running, startedAt: .now, lastActivityAt: .now)
        run.plan = [.storePage(.englishUS, .whatsNew), .appInformation(.notes)]
        for target in run.plan.prefix(received) {
            run.noteArrival(of: target, suggestionID: "sg_\(target.field)", at: .now)
        }
        run.phase = .finished
        return run
    }

    @Test func aFinishedRunOffersReviewByArea() {
        let toast = WorkspaceToast.finished(run(received: 2))
        #expect(toast.message.text == "Claude Code sent 2 suggestions: Store Page 1 · App Review 1.")
        #expect(toast.message.actionTitle == "Review by Area")
        #expect(toast.action == .openOverview("app1"))
        #expect(toast.undo == nil)
    }

    @Test func aRunThatFoundNothingOffersNothing() {
        let toast = WorkspaceToast.finished(run(received: 0))
        #expect(toast.message.text == "Claude Code looked at everything and found nothing new to suggest.")
        #expect(toast.message.actionTitle == nil)
        #expect(toast.action == nil)
    }

    @Test func acceptAllOffersUndo() {
        let undo = SuggestionRunAcceptance.Undo(review: SuggestionReviewState())
        let many = WorkspaceToast.accepted(18, undo: undo)
        #expect(many.message.text == "Accepted 18 suggestions. Nothing is pushed yet.")
        #expect(many.message.canUndo)
        #expect(many.undo == undo)
        #expect(WorkspaceToast.accepted(1, undo: undo).message.text == "Accepted 1 suggestion. Nothing is pushed yet.")
    }

    @Test func setupOffersSuggestEverything() {
        let toast = WorkspaceToast.connected("Claude Code")
        #expect(toast.message.text == "Claude Code is connected.")
        #expect(toast.message.actionTitle == "Suggest Everything")
        #expect(toast.action == .suggestEverything)
    }
}
