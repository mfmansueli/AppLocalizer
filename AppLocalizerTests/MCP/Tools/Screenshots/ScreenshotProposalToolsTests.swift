//
//  ScreenshotProposalToolsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `propose_template`, `propose_captions` and `list_proposals`: proposals
/// go into the screenshot document for the person to accept in the
/// Proposals sheet; nothing changes until they do.
@MainActor
@Suite("Screenshot proposal tools")
struct ScreenshotProposalToolsTests {
    private func call(
        _ tool: some MCPTool, _ arguments: [String: JSONValue], document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard
    ) async throws -> (MCPToolOutcome, CenteredScreenshotsServices) {
        let (workspace, services) = MCPScreenshotsFixtures.workspace(document)
        return try await (MCPScreenshotsFixtures.call(tool, arguments, in: workspace), services)
    }

    private static let smallerHeadline: JSONValue = [["op": "replace", "path": "caption.headline.size", "value": 104]]

    @Test func aTemplateProposalIsQueuedWithItsStressCheck() async throws {
        let (outcome, services) = try await call(ProposeTemplateTool(), [
            "basedOnVersion": 4, "ops": Self.smallerHeadline, "reason": "German overflows.",
        ])
        #expect(outcome.result["status"] == "queued")
        let id = try #require(outcome.result["proposalId"]?.stringValue)
        #expect(id.hasPrefix("sp-"))
        #expect(outcome.result["stale"] == nil)
        let stress = try #require(outcome.result["stress"]?.arrayValue)
        #expect(stress.first?["locale"] == "en-US")
        #expect(stress.contains { $0["locale"] == "ar-SA" })
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Screenshots", outcome: .proposed)])

        let document = try #require(services.storedDocument)
        let proposal = try #require(document.proposal(id: id))
        #expect(proposal.client == "Claude Code")
        #expect(proposal.status == .waiting)
        #expect(proposal.title == "Headline size")
        #expect(document.history?.currentNumber == 4)
        #expect(services.center.waitingProposals(appID: MCPScreenshotsFixtures.appID).count == 3)
    }

    @Test func aProposalOnAnOlderVersionIsQueuedAsStale() async throws {
        let (outcome, _) = try await call(ProposeTemplateTool(), [
            "basedOnVersion": 3, "ops": [["op": "replace", "path": "safe.top", "value": .double(0.08)]], "reason": "More air.",
        ])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["stale"] == "Based on v3, but the template is now v4. The person rebases it before accepting.")
    }

    @Test func aTemplateProposalThatDoesntApplyIsRefused() async throws {
        let (unknown, services) = try await call(ProposeTemplateTool(), [
            "basedOnVersion": 4, "ops": [["op": "replace", "path": "caption.glow", "value": true]], "reason": "Glow.",
        ])
        #expect(unknown.result["status"] == "refused")
        #expect(unknown.result["refusals"]?.arrayValue?.first?["path"] == "caption.glow")
        #expect(unknown.logLines.first?.outcome == .refused)
        #expect(services.storedDocument?.proposals.count == 2)

        let (missing, _) = try await call(ProposeTemplateTool(), ["basedOnVersion": 9, "ops": Self.smallerHeadline, "reason": "x"])
        #expect(missing.result["reason"] == "There’s no template v9; the current version is v4. Read it with get_template.")

        let (empty, _) = try await call(ProposeTemplateTool(), ["basedOnVersion": 4, "ops": [], "reason": "x"])
        #expect(empty.result["reason"] == "The proposal has no operations.")
    }

    @Test func captionsThatFitAreQueuedAndTheRestRefusedOneByOne() async throws {
        let (outcome, services) = try await call(ProposeCaptionsTool(), [
            "reason": "Shorter German.",
            "items": [
                ["locale": "de-DE", "slot": 3, "headline": "Einträge aus Jahren in Sekunden finden"],
                ["locale": "de-DE", "slot": 2, "headline": "Deine ganze Woche auf einer einzigen ruhigen und übersichtlichen Seite voller Erinnerungen"],
                ["locale": "xx", "slot": 1, "headline": "Hallo"],
                ["locale": "de-DE", "slot": 8, "headline": "Hallo"],
            ],
        ])
        #expect(outcome.result["status"] == "partial")
        let items = try #require(outcome.result["items"]?.arrayValue)
        #expect(items.compactMap { $0["status"]?.stringValue } == ["queued", "refused", "refused", "refused"])
        let overflow = items[1]["reason"]?.stringValue ?? ""
        #expect(overflow.hasPrefix("needs ") && overflow.hasSuffix("; the template allows 2"), "\(overflow)")
        #expect(items[2]["reason"] == "“xx” isn’t an App Store locale.")
        #expect(items[3]["reason"] == "The template has slots 1 to 5.")
        #expect(outcome.logLines.map(\.outcome) == [.proposed, .refused, .refused, .refused])

        let id = try #require(outcome.result["proposalId"]?.stringValue)
        let proposal = try #require(services.storedDocument?.proposal(id: id))
        #expect(proposal.title == "Captions for German")
        #expect(proposal.captions == [CaptionProposalItem(locale: "de-DE", slot: 2, headline: "Einträge aus Jahren in Sekunden finden")])
        let current = services.storedDocument?.captions.caption(locale: "de-DE", slot: 2)?.headline
        #expect(current == "Durchsuche jahrelange Tagebucheinträge in nur wenigen Sekunden")
    }

    @Test func whenNothingFitsNothingIsSaved() async throws {
        let (outcome, services) = try await call(ProposeCaptionsTool(), [
            "reason": "x", "items": [["locale": "de-DE", "slot": 1, "headline": "   "]],
        ])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["items"]?.arrayValue?.first?["reason"] == "The headline is empty.")
        #expect(outcome.result["proposalId"] == nil)
        #expect(services.storedDocument?.proposals.count == 2)

        let (noTemplate, _) = try await call(
            ProposeCaptionsTool(), ["reason": "x", "items": [["locale": "de-DE", "slot": 1, "headline": "Hallo"]]], document: .empty(primary: "en-US")
        )
        #expect(noTemplate.result["status"] == "refused")
    }

    @Test func proposalsAreListedWithTheirStatus() async throws {
        let (outcome, _) = try await call(ListProposalsTool(), [:], document: MCPScreenshotsFixtures.staleDocument)
        let proposals = try #require(outcome.result["proposals"]?.arrayValue)
        #expect(proposals.compactMap { $0["proposalId"]?.stringValue } == ["p3", "p1", "p2"])
        #expect(proposals.compactMap { $0["status"]?.stringValue } == ["stale", "pending", "pending"])
        #expect(proposals.compactMap { $0["kind"]?.stringValue } == ["template", "template", "captions"])
        #expect(proposals[0]["basedOn"] == 3)
        #expect(proposals[2]["captions"] == 3)
        #expect(proposals[2]["client"] == "Claude Code")
    }

    @Test func aProposalReachesTheOpenScreenshotsView() async throws {
        let (workspace, services) = MCPScreenshotsFixtures.workspace()
        let context = ScreenshotsContext(primaryLocale: .englishUS, version: ScreenshotsTestFixtures.editableVersion)
        let screen = ScreenshotsViewModel(app: ScreenshotsTestFixtures.app, services: services, context: context)
        await screen.load()
        screen.renderQueue.cancel()

        let outcome = try await MCPScreenshotsFixtures.call(ProposeCaptionsTool(), [
            "reason": "x", "items": [["locale": "fr-FR", "slot": 4, "headline": "Gardez les photos qui comptent"]],
        ], in: workspace)
        let id = try #require(outcome.result["proposalId"]?.stringValue)
        await ScreenshotsTestWaiting.until { screen.document?.proposal(id: id) != nil }
        #expect(screen.document?.proposal(id: id)?.status == .waiting)
        screen.renderQueue.cancel()
    }
}
