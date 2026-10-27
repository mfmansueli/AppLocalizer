//
//  ListMissingTranslationsToolTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("list_missing_translations")
struct ListMissingTranslationsToolTests {
    private func call(_ services: FakeStorePageServices = FakeStorePageServices(), changes: ChangeQueue = ChangeQueue()) async throws -> JSONValue {
        let workspace = MCPTestFixtures.workspace(apps: [StorePageContentFixtures.app], changes: changes, storePage: services)
        let context = MCPToolContext(workspace: workspace, clientName: "Claude Code")
        return try await ListMissingTranslationsTool().call(MCPToolArguments(["appId": "app1"]), in: context).result
    }

    @Test func listsEmptyFieldsWithThePrimaryText() async throws {
        let result = try await call()
        #expect(result["missingCount"] == 6)
        #expect(result["note"] == nil)
        let locales = try #require(result["locales"]?.arrayValue)
        #expect(locales.map { $0["locale"] } == ["de-DE"])
        let fields = try #require(locales.first?["fields"]?.arrayValue)
        #expect(fields.compactMap { $0["field"]?.stringValue } == [
            "privacyPolicyUrl", "promotionalText", "keywords", "whatsNew", "supportUrl", "marketingUrl",
        ])
        #expect(fields[1] == [
            "field": "promotionalText", "source": "Weekly Reflections are here.",
            "limit": ["max": 170, "unit": "characters"], "copyAsIs": false,
        ])
        #expect(fields[0]["copyAsIs"] == true)
    }

    @Test func proposedFieldsArentMissing() async throws {
        var listing = StorePageContentFixtures.editable.listing()
        _ = listing.propose("Wöchentliche Rückblicke sind da.", for: .promotionalText, in: .german, by: "Claude Code")
        let builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        let changes = ChangeQueue()
        changes.upsert(contentsOf: builder.changes(for: listing))

        let result = try await call(changes: changes)
        #expect(result["missingCount"] == 5)
    }

    @Test func aReadOnlyVersionOffersOnlyAppFields() async throws {
        let result = try await call(FakeStorePageServices(contents: [StorePageContentFixtures.liveOnly]))
        #expect(result["missingCount"] == 1)
        #expect(result["locales"]?.arrayValue?.first?["fields"]?.arrayValue?.first?["field"] == "privacyPolicyUrl")
        #expect(result["note"]?.stringValue?.hasPrefix("Version 1.9 is read-only") == true)
    }
}
