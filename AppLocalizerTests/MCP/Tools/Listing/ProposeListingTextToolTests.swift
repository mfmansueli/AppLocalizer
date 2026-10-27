//
//  ProposeListingTextToolTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("propose_listing_text")
struct ProposeListingTextToolTests {
    private let changes = ChangeQueue()
    private let builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")

    private func call(_ arguments: [String: JSONValue], services: FakeStorePageServices = FakeStorePageServices()) async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(apps: [StorePageContentFixtures.app], changes: changes, storePage: services)
        var arguments = arguments
        arguments["appId"] = "app1"
        return try await ProposeListingTextTool().call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))
    }

    @Test func aProposalIsQueuedForReviewAsTheAssistants() async throws {
        let outcome = try await call(["locale": "de-DE", "field": "promotionalText", "text": "Wöchentliche Rückblicke sind da."])

        let id = StorePageContentFixtures.changeID(.german, .promotionalText)
        #expect(outcome.result == ["locale": "de-DE", "field": "promotionalText", "status": "queued", "changeId": .string(id)])
        let change = try #require(changes.change(id: id))
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.newValue == "Wöchentliche Rückblicke sind da.")
        #expect(change.oldValue == "")
        #expect(outcome.logLines == [.init(target: "Lumen Journal · de-DE · Promotional Text", outcome: .proposed)])
    }

    @Test func textOverTheLimitIsRefusedWithTheCount() async throws {
        let outcome = try await call(["locale": "de-DE", "field": "subtitle", "text": "Private Notizen, sanfte Fragen!"])
        #expect(!outcome.isError)
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["count"] == 31)
        #expect(outcome.result["limit"] == ["max": 30, "unit": "characters"])
        #expect(outcome.result["reason"] == "Over the limit: 31 of 30 characters. Fix it and propose again.")
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.first?.outcome == .refused)
    }

    @Test func thePersonsOwnChangeKeepsBothVersions() async throws {
        var listing = StorePageContentFixtures.editable.listing()
        listing.edit(.subtitle, in: .german, to: "Notizen, nur für dich")
        changes.upsert(contentsOf: builder.changes(for: listing))

        let outcome = try await call(["locale": "de-DE", "field": "subtitle", "text": "Deine privaten Notizen"])

        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["note"] != nil)
        let change = try #require(changes.change(id: StorePageContentFixtures.changeID(.german, .subtitle)))
        #expect(change.source == .you)
        #expect(change.newValue == "Notizen, nur für dich")
        #expect(change.alternative?.source == .assistant(client: "Claude Code"))
        #expect(change.alternative?.newValue == "Deine privaten Notizen")
    }

    @Test func theCurrentTextIsUnchanged() async throws {
        let outcome = try await call(["locale": "de-DE", "field": "subtitle", "text": "Private Notizen, sanfte Fragen"])
        #expect(outcome.result["status"] == "unchanged")
        #expect(changes.changes.isEmpty)
        #expect(outcome.logLines.first?.outcome == .read)
    }

    @Test func proposingTheLiveTextAgainWithdrawsAProposal() async throws {
        _ = try await call(["locale": "de-DE", "field": "subtitle", "text": "Deine privaten Notizen"])
        #expect(changes.changes.count == 1)
        let outcome = try await call(["locale": "de-DE", "field": "subtitle", "text": "Private Notizen, sanfte Fragen"])
        #expect(outcome.result["status"] == "unchanged")
        #expect(changes.changes.isEmpty)
    }

    @Test func aReadOnlyVersionTakesOnlyAppFields() async throws {
        let services = FakeStorePageServices(contents: [StorePageContentFixtures.liveOnly])
        let description = try await call(["locale": "de-DE", "field": "description", "text": "Neu."], services: services)
        #expect(description.result["status"] == "refused")
        #expect(description.result["reason"] == "Version 1.9 is read-only and there’s no editable version.")

        let subtitle = try await call(["locale": "de-DE", "field": "subtitle", "text": "Deine privaten Notizen"], services: services)
        #expect(subtitle.result["changeId"] == .string(StorePageContentFixtures.changeID(.german, .subtitle)))
    }

    @Test func aBatchReportsEachProposal() async throws {
        let proposals: JSONValue = [
            ["locale": "de-DE", "field": "keywords", "text": "tagebuch,stimmung,dankbarkeit"],
            ["locale": "fr-FR", "field": "keywords", "text": "journal,humeur"],
            ["locale": "xx", "field": "whats_new", "text": "Neu."],
        ]
        let outcome = try await call(["proposals": proposals])

        #expect(outcome.result["queued"] == 1)
        #expect(outcome.result["refused"] == 2)
        let results = try #require(outcome.result["results"]?.arrayValue)
        #expect(results.map { $0["status"] } == ["queued", "refused", "refused"])
        #expect(results[1]["reason"]?.stringValue?.contains("isn’t one of this app’s locales yet") == true)
        #expect(results[2]["field"] == "whatsNew")
        #expect(outcome.logLines.map(\.outcome) == [.proposed, .refused, .refused])
        #expect(changes.changes.count == 1)
    }

    @Test func badArgumentsAreErrors() async {
        await #expect(throws: MCPToolError.self) { try await call(["locale": "de-DE", "field": "tagline", "text": "x"]) }
        await #expect(throws: MCPToolError.self) { try await call(["locale": "de-DE", "field": "subtitle"]) }
        await #expect(throws: MCPToolError.self) { try await call(["proposals": ["de-DE"]]) }
    }

    @Test func fieldsAreMatchedByTheirAPIName() {
        #expect(ListingField.matching("whatsNew") == .whatsNew)
        #expect(ListingField.matching("WHATS_NEW") == .whatsNew)
        #expect(ListingField.matching("privacyPolicyURL") == .privacyPolicyURL)
        #expect(ListingField.matching("tagline") == nil)
        #expect(ProposeListingTextTool().definition.proposalKind == .storeText)
    }
}
