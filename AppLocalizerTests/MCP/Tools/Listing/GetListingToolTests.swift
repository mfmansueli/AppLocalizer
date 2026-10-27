//
//  GetListingToolTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("get_listing")
struct GetListingToolTests {
    private let services = FakeStorePageServices()
    private let changes = ChangeQueue()

    private func call(_ arguments: [String: JSONValue], glossary: TranslationGlossary = TranslationGlossary()) async throws -> MCPToolOutcome {
        let workspace = MCPTestFixtures.workspace(apps: [StorePageContentFixtures.app], changes: changes, storePage: services, glossary: glossary)
        return try await GetListingTool().call(MCPToolArguments(arguments), in: MCPToolContext(workspace: workspace, clientName: "Claude Code"))
    }

    @Test func readsTheEditableVersionsTextsPerLocale() async throws {
        let outcome = try await call(["appId": "Lumen Journal"])
        let result = outcome.result
        #expect(result["appId"] == "app1")
        #expect(result["version"] == ["versionString": "2.0", "state": "Prepare for Submission", "editable": true])
        #expect(result["primaryLocale"] == "en-US")
        let locales = try #require(result["locales"]?.arrayValue)
        #expect(locales.map { $0["code"] } == ["en-US", "de-DE"])
        #expect(locales[0]["texts"]?["subtitle"] == "Private notes, gentle prompts")
        #expect(locales[0]["states"] == nil)
        #expect(locales[1]["texts"]?["promotionalText"] == nil)
        #expect(locales[1]["states"]?["promotionalText"] == "missing")
        #expect(outcome.logLines == [.init(target: "Lumen Journal · version 2.0", outcome: .read)])
    }

    @Test func describesEachFieldsLevelAndLimit() async throws {
        let fields = try await call(["appId": "app1"]).result["fields"]
        #expect(fields?["subtitle"] == ["level": "app", "limit": ["max": 30, "unit": "characters"], "editable": true])
        #expect(fields?["keywords"]?["limit"] == ["max": 100, "unit": "bytes"])
        #expect(fields?["supportUrl"]?["limit"] == .null)
        #expect(fields?["whatsNew"]?["level"] == "version")
    }

    @Test func includesTheGlossaryAndTone() async throws {
        let glossary = TranslationGlossary(terms: ["Lumen Plus"], tone: .playful)
        let result = try await call(["appId": "app1"], glossary: glossary).result
        #expect(result["glossary"] == ["keepUntranslated": ["Lumen Plus"], "tone": "playful"])
    }

    @Test func queuedChangesAreLaidOnTop() async throws {
        var listing = StorePageContentFixtures.editable.listing()
        listing.edit(.promotionalText, in: .german, to: "Wöchentliche Rückblicke sind da.")
        let builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        changes.upsert(contentsOf: builder.changes(for: listing))

        let german = try await call(["appId": "app1", "locales": ["de-DE"]]).result["locales"]?.arrayValue?.first
        #expect(german?["texts"]?["promotionalText"] == "Wöchentliche Rückblicke sind da.")
        #expect(german?["states"]?["promotionalText"] == "changed by the person, waiting in review")
    }

    @Test func unknownLocalesAndUnreadableListingsAreErrors() async {
        await #expect(throws: MCPToolError.self) { try await call(["appId": "app1", "locales": ["fr-FR"]]) }
        services.error = AppStoreConnectError.notFound(detail: nil)
        do {
            _ = try await call(["appId": "app1"])
            Issue.record("Expected an error")
        } catch {
            #expect(error.localizedDescription.hasPrefix("Couldn’t read Lumen Journal’s store listing"))
        }
    }
}
