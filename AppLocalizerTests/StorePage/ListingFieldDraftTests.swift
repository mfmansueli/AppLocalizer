//
//  ListingFieldDraftTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("ListingFieldDraft")
struct ListingFieldDraftTests {
    private let client = StorePageFixtures.client

    /// "Mine" is your pending change, "Theirs" the assistant's proposal.
    private func conflicted() -> ListingFieldDraft {
        var draft = ListingFieldDraft(remote: "Remote")
        draft.edit("Mine")
        _ = draft.propose("Theirs", by: client)
        return draft
    }

    // MARK: - Editing

    @Test func startsInSyncWithAppStoreConnect() {
        let draft = ListingFieldDraft(remote: "Hallo")
        #expect(draft.local == "Hallo")
        #expect(!draft.isPending)
        #expect(draft.source == .you)
    }

    @Test func editingBackToTheRemoteValueIsNotPending() {
        var draft = ListingFieldDraft(remote: "A")
        draft.edit("B")
        #expect(draft.isPending)
        draft.edit("A")
        #expect(!draft.isPending)
    }

    @Test func discardRestoresTheRemoteValue() {
        var draft = ListingFieldDraft(remote: "A")
        draft.acceptMachineTranslation("B")
        draft.discard()
        #expect(draft.local == "A")
        #expect(!draft.isPending)
        #expect(!draft.isMachineTranslated)
    }

    // MARK: - Machine translation

    @Test func editingClearsTheMachineTranslationTag() {
        var draft = ListingFieldDraft()
        draft.acceptMachineTranslation("Hallo")
        #expect(draft.isMachineTranslated)
        #expect(draft.source == .machineTranslation)
        draft.edit("Hallo!")
        #expect(!draft.isMachineTranslated)
        #expect(draft.source == .you)
    }

    @Test func reviewingKeepsTheTextButDropsTheTag() {
        var draft = ListingFieldDraft(remote: "日記", isMachineTranslated: true)
        #expect(!draft.isPending)
        draft.markReviewed()
        #expect(!draft.isMachineTranslated)
        #expect(draft.local == "日記")
        #expect(!draft.isPending)
    }

    @Test func pushingKeepsTheMachineTranslationTag() {
        var draft = ListingFieldDraft()
        draft.acceptMachineTranslation("Hallo")
        draft.markPushed()
        #expect(draft.remote == "Hallo")
        #expect(!draft.isPending)
        #expect(draft.isMachineTranslated)
    }

    // MARK: - Remote updates

    @Test func remoteUpdatesFollowUnlessYouHaveAChange() {
        var synced = ListingFieldDraft(remote: "A")
        synced.updateRemote("B")
        #expect(synced.local == "B")
        #expect(!synced.isPending)

        var edited = ListingFieldDraft(remote: "A")
        edited.edit("Mine")
        edited.updateRemote("B")
        #expect(edited.local == "Mine")
        #expect(edited.remote == "B")
        edited.updateRemote("Mine")
        #expect(!edited.isPending)
    }

    // MARK: - Proposals

    @Test func proposalOnAnUntouchedFieldIsQueued() {
        var draft = ListingFieldDraft(remote: "A")
        let first = draft.propose("B", by: client)
        #expect(first == .queued)
        #expect(draft.local == "B")
        #expect(draft.source == .assistant(client: client))
        let again = draft.propose("B", by: client)
        #expect(again == .unchanged)
    }

    @Test func proposingTheRemoteValueLeavesNothingPending() {
        var draft = ListingFieldDraft(remote: "A")
        _ = draft.propose("B", by: client)
        let outcome = draft.propose("A", by: client)
        #expect(outcome == .queued)
        #expect(!draft.isPending)
        #expect(draft.proposedBy == nil)
    }

    @Test func aSecondProposalReplacesTheFirst() {
        var draft = ListingFieldDraft(remote: "A")
        _ = draft.propose("B", by: client)
        let outcome = draft.propose("C", by: client)
        #expect(outcome == .queued)
        #expect(draft.local == "C")
        #expect(!draft.hasConflict)
    }

    @Test func proposalOnYourChangeIsAConflict() {
        var draft = ListingFieldDraft(remote: "Remote")
        draft.edit("Mine")
        let outcome = draft.propose("Theirs", by: client)
        #expect(outcome == .conflict)
        #expect(outcome.status == "queued")
        #expect(draft.local == "Mine")
        #expect(draft.conflictingProposal == ListingAssistantProposal(client: client, value: "Theirs"))
    }

    @Test func keepingYourValue() {
        var draft = conflicted()
        draft.resolveConflict(keeping: .yours)
        #expect(draft.local == "Mine")
        #expect(!draft.hasConflict)
        #expect(draft.source == .you)
    }

    @Test func keepingTheAssistantsValue() {
        var draft = conflicted()
        draft.resolveConflict(keeping: .assistant)
        #expect(draft.local == "Theirs")
        #expect(!draft.hasConflict)
        #expect(draft.source == .assistant(client: client))
    }

    @Test func typingTheProposedValueEndsTheConflict() {
        var draft = conflicted()
        draft.edit("Theirs")
        #expect(!draft.hasConflict)
        #expect(draft.source == .you)
    }

    @Test func revertingYourChangeLeavesTheProposal() {
        var draft = conflicted()
        draft.edit("Remote")
        #expect(draft.local == "Theirs")
        #expect(draft.source == .assistant(client: client))
        #expect(!draft.hasConflict)
    }

    @Test func discardingAClientsProposals() {
        var proposed = ListingFieldDraft(remote: "A")
        _ = proposed.propose("B", by: client)
        let droppedOther = proposed.discardProposal(from: "Other Client")
        let droppedOwn = proposed.discardProposal(from: client)
        #expect(!droppedOther)
        #expect(droppedOwn)
        #expect(proposed.local == "A")

        var draft = conflicted()
        let droppedConflict = draft.discardProposal(from: client)
        #expect(droppedConflict)
        #expect(draft.local == "Mine")
        #expect(!draft.hasConflict)
    }

    @Test func pushingClearsTheAttribution() {
        var draft = ListingFieldDraft(remote: "A")
        _ = draft.propose("B", by: client)
        draft.markPushed()
        #expect(draft.proposedBy == nil)
        #expect(draft.source == .you)
    }
}
