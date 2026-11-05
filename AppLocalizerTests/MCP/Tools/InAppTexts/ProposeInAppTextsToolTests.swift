//
//  ProposeInAppTextsToolTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `get_in_app_texts` and `propose_in_app_texts`: the subscription group
/// name and product texts, queued for review as the assistant's.
@MainActor
@Suite("propose_in_app_texts")
struct ProposeInAppTextsToolTests {
    private let changes = ChangeQueue()
    private let monthly = InAppTextProduct(id: "lumen.monthly", referenceName: "Monthly", kind: .subscription)

    /// A group without any localization (App Store Connect's "You must add
    /// at least one subscription group localization") and one subscription.
    private var content: InAppTextsContent {
        InAppTextsContent(
            products: [monthly],
            texts: [.englishUS: ["lumen.monthly.name": "Lumen Plus", "lumen.monthly.description": "Unlimited photos"]],
            groupID: "grp",
            productResourceIDs: ["lumen.monthly": "sub1"],
            productLocalizations: ["lumen.monthly": [.englishUS: "sl-en"]],
            editableVersions: [InAppTextsContent.groupKey: "gv1", "lumen.monthly": "sv1"]
        )
    }

    private func workspace() -> MCPWorkspace {
        let services = FakeStorePageServices()
        services.inAppTextsContent = content
        return MCPTestFixtures.workspace(apps: [StorePageContentFixtures.app], changes: changes, storePage: services)
    }

    private func propose(_ arguments: [String: JSONValue]) async throws -> MCPToolOutcome {
        var arguments = arguments
        arguments["appId"] = "app1"
        return try await ProposeInAppTextsTool().call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace(), clientName: "Claude Code"))
    }

    @Test func aGroupNameForANewLocaleIsPostedAsTheAssistants() async throws {
        let outcome = try await propose(["locale": "en-US", "column": "group.name", "text": "Lumen Plus"])

        let id = "storePage.app1.inApp.group.grp.en-US.new"
        #expect(outcome.result == ["locale": "en-US", "column": "group.name", "status": "queued", "changeId": .string(id)])
        let change = try #require(changes.change(id: id))
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.requests.first?.method == .post)
        #expect(change.requests.first?.path == "/v2/subscriptionGroupLocalizations")
        let body = try #require(StorePageWriteDocument.decode(change.requests.first?.body))
        #expect(body.attribute("name") == "Lumen Plus")
        #expect(outcome.logLines == [.init(target: "Lumen Journal · en-US · Group name", outcome: .proposed)])
    }

    @Test func aBatchReportsEachProposal() async throws {
        let proposals: JSONValue = [
            ["locale": "en-US", "column": "group.name", "text": "Lumen Plus"],
            ["locale": "de-DE", "column": "group.name", "text": "Lumen Plus"],
            ["locale": "de-DE", "column": "nope", "text": "x"],
        ]
        let outcome = try await propose(["proposals": proposals])
        #expect(outcome.result["queued"] == 2)
        #expect(outcome.result["refused"] == 1)
        #expect(changes.changes.count == 2)
    }

    @Test func overTheLimitIsRefusedWithTheCount() async throws {
        let outcome = try await propose(["locale": "en-US", "column": "group.name", "text": .string(String(repeating: "a", count: 31))])
        #expect(outcome.result["status"] == "refused")
        #expect(outcome.result["count"] == 31)
        #expect(outcome.result["limit"] == ["max": 30, "unit": "characters"])
        #expect(changes.changes.isEmpty)
    }

    @Test func aDescriptionAloneForANewLocaleWaitsForAName() async throws {
        let outcome = try await propose(["locale": "de-DE", "column": "lumen.monthly.description", "text": "Unbegrenzt Fotos"])
        #expect(outcome.result["status"] == "queued")
        #expect(outcome.result["blockedReason"] != nil)
    }

    @Test func thePersonsOwnChangeIsLeftToThem() async throws {
        let builder = InAppTextChangeBuilder(appID: "app1", content: content)
        var matrix = content.matrix(primaryLocale: .englishUS, locales: [.englishUS, .german])
        let column = try #require(matrix.columns.first { $0.id == "lumen.monthly.name" })
        matrix.edit(column, in: .englishUS, to: "Lumen Plus Monthly")
        changes.upsert(contentsOf: builder.changes(for: matrix))

        let outcome = try await propose(["locale": "en-US", "column": "lumen.monthly.name", "text": "Lumen Monthly"])
        #expect(outcome.result["status"] == "refused")
        #expect(changes.changes.first?.newValue == "Lumen Plus Monthly")
    }

    @Test func proposingTheLiveTextAgainWithdrawsAProposal() async throws {
        _ = try await propose(["locale": "en-US", "column": "lumen.monthly.name", "text": "Lumen Monthly"])
        #expect(changes.changes.count == 1)
        let outcome = try await propose(["locale": "en-US", "column": "lumen.monthly.name", "text": "Lumen Plus"])
        #expect(outcome.result["status"] == "unchanged")
        #expect(changes.changes.isEmpty)
    }

    @Test func theAssistantsTagSurvivesTheViewReadingTheQueue() async throws {
        _ = try await propose(["locale": "en-US", "column": "group.name", "text": "Lumen Plus"])
        let services = FakeStorePageServices()
        services.inAppTextsContent = content
        let model = InAppTextsViewModel(app: StorePageContentFixtures.app, services: services, queue: changes)
        await model.load(listing: StorePageContentFixtures.editable.listing())
        let description = try #require(model.matrix?.columns.first { $0.id == "lumen.monthly.description" })
        model.edit(description, in: .englishUS, to: "Unlimited photos and themes")

        #expect(changes.change(id: "storePage.app1.inApp.group.grp.en-US.new")?.source == .assistant(client: "Claude Code"))
        #expect(changes.change(id: "storePage.app1.inApp.product.sub1.en-US.description")?.source == .you)
    }

    @Test func getListsColumnsTextsAndWhatsMissing() async throws {
        let outcome = try await GetInAppTextsTool().call(
            MCPToolArguments(["appId": "app1", "locales": ["en-US"]]),
            in: MCPToolContext(workspace: workspace(), clientName: "Claude Code")
        )
        #expect(outcome.result["hasSubscriptionGroup"] == true)
        #expect(outcome.result["columns"]?.arrayValue?.compactMap { $0["id"]?.stringValue } == [
            "group.name", "lumen.monthly.name", "lumen.monthly.description",
        ])
        let english = try #require(outcome.result["locales"]?.arrayValue?.first)
        #expect(english["missing"] == ["group.name"])
        #expect(english["texts"]?["lumen.monthly.name"] == "Lumen Plus")
    }
}
