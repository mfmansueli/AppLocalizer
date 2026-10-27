//
//  ScreenshotsDocumentProposalsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("Deciding screenshot proposals")
struct ScreenshotsDocumentProposalsTests {
    private let date = ScreenshotsSampleData.date(month: 10, day: 27, hour: 11)

    private var document: ScreenshotsDocument { ScreenshotsDebugDocuments.standard }

    @Test func theSampleHasATemplateAndACaptionProposalWaiting() {
        let document = document
        #expect(document.waitingProposals.map(\.id) == ["p1", "p2"])
        #expect(document.proposal(locale: "de-DE", slot: 1)?.id == "p2")
        #expect(document.proposal(locale: "de-DE", slot: 0) == nil)
        #expect(document.proposal(id: "p1")?.basedOnVersion == 4)
    }

    @Test func acceptingATemplateProposalSavesTheNextVersionTaggedWithTheAssistant() throws {
        var document = document
        let result = document.acceptTemplateProposal("p1", date: date)
        let version = try result.get()
        #expect(version.number == 5)
        #expect(version.author == .assistant(client: "Claude Code"))
        #expect(version.note == "Smaller headline, hyphenation on")
        let template = try #require(document.template)
        #expect(template.caption.headline.size == 104)
        #expect(template.caption.headline.min == 72)
        #expect(template.fit.hyphenate)
        #expect(template.device.width == 0.78)
        #expect(document.proposal(id: "p1")?.status == .accepted)
        #expect(document.proposal(id: "p1")?.decidedAt == date)
        // Deciding twice does nothing.
        #expect((try? document.acceptTemplateProposal("p1", date: date).get()) == nil)
    }

    @Test func aStaleTemplateProposalIsntAcceptedUntilRebased() {
        var document = document
        document.history = ScreenshotsSampleData.staleHistory
        document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
        #expect(document.proposal(id: "p3")?.isStale(currentVersion: 4) == true)
        #expect((try? document.acceptTemplateProposal("p3", date: date).get()) == nil)
        #expect(document.history?.currentNumber == 4)
        #expect(document.proposal(id: "p3")?.status == .waiting)
    }

    @Test func rebasingKeepsYoursOnConflictsByDefault() throws {
        var document = document
        document.history = ScreenshotsSampleData.staleHistory
        document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
        document.rebaseProposal("p3", choices: [:])
        let rebased = try #require(document.proposal(id: "p3"))
        #expect(rebased.basedOnVersion == 4)
        #expect(rebased.template?.rebasedFrom == 3)
        #expect(rebased.template?.operations.map(\.path) == ["safe.top"])
        #expect(!rebased.isStale(currentVersion: 4))
        _ = try document.acceptTemplateProposal("p3", date: date).get()
        #expect(document.template?.device.width == 0.78)
        #expect(document.template?.safeArea.top == 0.08)
    }

    @Test func rebasingCanUseTheAssistantsValue() throws {
        var document = document
        document.history = ScreenshotsSampleData.staleHistory
        document.proposals.insert(ScreenshotsSampleData.staleProposal, at: 0)
        document.rebaseProposal("p3", choices: ["device.width": .useTheirs])
        _ = try document.acceptTemplateProposal("p3", date: date).get()
        #expect(document.template?.device.width == 0.76)
        #expect(document.history?.currentNumber == 5)
    }

    @Test func acceptingSomeCaptionsRejectsTheRest() throws {
        var document = document
        let accepted = document.acceptCaptions(of: "p2", keys: [LocaleSlot(locale: "de-DE", slot: 1)], date: date)
        #expect(accepted == 1)
        let proposal = try #require(document.proposal(id: "p2"))
        #expect(proposal.status == .partlyAccepted)
        #expect(proposal.captions.map(\.decision) == [.accepted, .rejected, .rejected])
        let week = try #require(document.captions.caption(locale: "de-DE", slot: 1))
        #expect(week.headline == "Deine Woche auf einen Blick")
        #expect(week.provenance == .assistant(client: "Claude Code", date: proposal.receivedAt))
        #expect(document.captions.caption(locale: "de-DE", slot: 2)?.headline == "Durchsuche jahrelange Tagebucheinträge in nur wenigen Sekunden")
        #expect(document.proposal(locale: "de-DE", slot: 2) == nil)
    }

    @Test func acceptingEveryCaptionKeepsTheirSubheads() {
        var document = document
        document.captions.setCaption(ScreenshotCaption(headline: "Alt", subhead: "Bleibt", provenance: .reviewed), locale: "de-DE", slot: 1)
        #expect(document.acceptCaptions(of: "p2", date: date) == 3)
        #expect(document.proposal(id: "p2")?.status == .accepted)
        #expect(document.captions.caption(locale: "de-DE", slot: 1)?.subhead == "Bleibt")
    }

    @Test func acceptingNoCaptionsIsARejection() {
        var document = document
        #expect(document.acceptCaptions(of: "p2", keys: [], date: date) == 0)
        #expect(document.proposal(id: "p2")?.status == .rejected)
    }

    @Test func rejectingChangesNothing() {
        var document = document
        let before = document.captions
        document.rejectProposal("p2", date: date)
        document.rejectProposal("p1", date: date)
        #expect(document.captions == before)
        #expect(document.history?.currentNumber == 4)
        #expect(document.waitingProposals.isEmpty)
        #expect(document.proposal(id: "p2")?.captions.allSatisfy { $0.decision == .rejected } == true)
    }

    @Test func proposalsSurviveSavingAndLoading() throws {
        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(ScreenshotsDocument.self, from: data)
        #expect(decoded.proposals == document.proposals)
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains("\"ops\""))
    }
}
