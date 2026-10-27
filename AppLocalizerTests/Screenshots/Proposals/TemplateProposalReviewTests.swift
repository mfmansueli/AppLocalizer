//
//  TemplateProposalReviewTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("TemplateProposalReview")
struct TemplateProposalReviewTests {
    private func review(_ proposal: ScreenshotProposal, history: TemplateHistory = ScreenshotsSampleData.history) throws -> TemplateProposalReview {
        try TemplateProposalReview(proposal: #require(proposal.template), history: history)
    }

    @Test func readsEachChangeAsOldToNew() throws {
        let review = try review(ScreenshotsSampleData.templateProposal)
        #expect(!review.isStale)
        #expect(review.nextNumber == 5)
        #expect(review.rows.map(\.change.title) == ["Headline size", "Headline smallest size", "Hyphenation", "Device width"])
        #expect(review.rows.map(\.change.oldText) == ["112 u", "80 u", "off", "80%"])
        #expect(review.rows.map(\.change.newText) == ["104 u", "72 u", "on", "78%"])
        #expect(review.conflicts.isEmpty)
    }

    @Test func aStaleProposalListsWhatChangedSinceAndItsConflicts() throws {
        let review = try review(ScreenshotsSampleData.staleProposal, history: ScreenshotsSampleData.staleHistory)
        #expect(review.isStale)
        #expect(review.versionsSince.map(\.note) == ["Device width 80% → 78%"])
        #expect(review.rows.map(\.change.oldText) == ["6%", "80%"])
        let conflict = try #require(review.conflicts.first)
        #expect(review.conflicts.count == 1)
        #expect(conflict.change.path == "device.width")
        #expect(conflict.currentText == "78%")
        #expect(review.operations().map(\.path) == ["safe.top"])
        #expect(review.operations(choices: ["device.width": .useTheirs]).map(\.path) == ["safe.top", "device.width"])
    }

    @Test func theProposedTemplateIsTheCurrentOneWithTheOperations() throws {
        let review = try review(ScreenshotsSampleData.staleProposal, history: ScreenshotsSampleData.staleHistory)
        let kept = try review.proposedTemplate().get()
        #expect(kept.device.width == 0.78)
        #expect(kept.safeArea.top == 0.08)
        let theirs = try review.proposedTemplate(choices: ["device.width": .useTheirs]).get()
        #expect(theirs.device.width == 0.76)
    }

    @Test func anOperationOnAPathThatDoesntExistIsRefused() throws {
        let proposal = ScreenshotProposal.template(
            id: "x", client: "Claude Code", receivedAt: .now, title: "x", reason: "x",
            proposal: TemplateProposal(basedOn: 4, operations: [.replace("caption.glow", with: true)])
        )
        let review = try review(proposal)
        #expect(throws: TemplateRefusals.self) { try review.proposedTemplate().get() }
    }
}
