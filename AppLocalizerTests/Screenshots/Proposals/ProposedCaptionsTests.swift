//
//  ProposedCaptionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Caption proposals one caption at a time, as the Screenshots language page
/// and its badges count them: what waits, the newest per slot, and deciding
/// some of them.
@Suite("Proposed captions")
struct ProposedCaptionsTests {
    private let decided = Date(timeIntervalSince1970: 1_800_000_000)

    /// A minute after the sample's p2, which is stamped "today at 10:43":
    /// `.now` plus an hour is older than that before 9:43.
    private func newer(than document: ScreenshotsDocument) -> Date {
        (document.proposals.first { $0.id == "p2" }?.receivedAt ?? .now).addingTimeInterval(60)
    }

    @Test func theSampleProposalWaitsInGermanOnly() throws {
        let document = ScreenshotsDebugDocuments.standard
        let open = document.openProposedCaptions
        #expect(open.map(\.slot) == [1, 2, 4])
        #expect(Set(open.map(\.locale)) == ["de-DE"])
        let first = try #require(open.first)
        #expect(first.item.headline == "Deine Woche auf einen Blick")
        #expect(first.title == "Screenshot 2 · caption")
        #expect(first.id == "p2|de-DE|1")
        #expect(first.source == .assistant(client: "Claude Code"))
        #expect(document.openProposedCaptions(in: "en-US").isEmpty)
    }

    @Test func aNewerProposalForTheSameSlotIsTheOneThatCounts() {
        var document = ScreenshotsDebugDocuments.standard
        document.proposals.append(.captions(
            id: "p9", client: "Claude Code", receivedAt: newer(than: document), title: "Even shorter", reason: "Fits.",
            items: [CaptionProposalItem(locale: "de-DE", slot: 1, headline: "Deine Woche")]
        ))
        let open = document.openProposedCaptions
        #expect(open.count == 3)
        #expect(open.first { $0.slot == 1 }?.proposalID == "p9")
    }

    @Test func acceptingSomeLeavesTheRestWaiting() throws {
        var document = ScreenshotsDebugDocuments.standard
        let count = document.decideCaptions(["p2|de-DE|1"], accept: true, date: decided)
        #expect(count == 1)
        #expect(document.captions.caption(locale: "de-DE", slot: 1)?.headline == "Deine Woche auf einen Blick")
        #expect(document.openProposedCaptions.map(\.slot) == [2, 4])
        let proposal = try #require(document.proposals.first { $0.id == "p2" })
        #expect(proposal.status == .waiting)
    }

    @Test func theProposalSettlesOnceNothingWaits() throws {
        var document = ScreenshotsDebugDocuments.standard
        document.decideCaptions(["p2|de-DE|1"], accept: true, date: decided)
        document.decideCaptions(["p2|de-DE|2", "p2|de-DE|4"], accept: false, date: decided)
        #expect(document.openProposedCaptions.isEmpty)
        let proposal = try #require(document.proposals.first { $0.id == "p2" })
        #expect(proposal.status == .partlyAccepted)
        #expect(proposal.decidedAt == decided)
    }

    @Test func acceptingTheNewerOneRejectsTheOlderForThatSlot() throws {
        var document = ScreenshotsDebugDocuments.standard
        document.proposals.append(.captions(
            id: "p9", client: "Claude Code", receivedAt: newer(than: document), title: "Even shorter", reason: "Fits.",
            items: [CaptionProposalItem(locale: "de-DE", slot: 1, headline: "Deine Woche")]
        ))
        document.decideCaptions(["p9|de-DE|1"], accept: true, date: decided)
        #expect(document.captions.caption(locale: "de-DE", slot: 1)?.headline == "Deine Woche")
        let older = try #require(document.proposals.first { $0.id == "p2" })
        #expect(older.captions.first { $0.slot == 1 }?.decision == .rejected)
        #expect(document.proposals.first { $0.id == "p9" }?.status == .accepted)
    }

    @Test func unknownIDsDecideNothing() {
        var document = ScreenshotsDebugDocuments.standard
        #expect(document.decideCaptions(["nope"], accept: true, date: decided) == 0)
        #expect(document.openProposedCaptions.count == 3)
    }
}
#endif
