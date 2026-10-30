//
//  SuggestionReadToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `get_store_page` and `get_app_information`: what an assistant reads
/// before suggesting, with the suggestions already open so it doesn't
/// repeat them.
@MainActor
@Suite("get_store_page and get_app_information")
struct SuggestionReadToolsTests {
    private let store = FieldSuggestionStore()
    private let lumen = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Information", bundleID: "dev.example.info", sku: nil, primaryLocale: "en-US")

    private func context() -> MCPToolContext {
        var workspace = MCPTestFixtures.workspace(
            apps: [StorePageContentFixtures.app, lumen],
            storePage: FakeStorePageServices(),
            appInformation: DebugAppInformationServices()
        )
        workspace.suggestions = store
        return MCPToolContext(workspace: workspace, clientName: "Claude Code")
    }

    @Test func theStorePageListsTextsLimitsAndOpenSuggestions() async throws {
        let open = store.add(
            appID: StorePageContentFixtures.app.id,
            target: .storePage(.german, .whatsNew),
            value: "Neu",
            reason: "Translated.",
            source: .assistant(client: "Claude Code")
        ).suggestion
        let outcome = try await GetStorePageTool().call(MCPToolArguments(["appId": "app1", "locales": ["de-DE"]]), in: context())
        let result = outcome.result
        #expect(result["primaryLocale"] == "en-US")
        #expect(result["fields"]?["subtitle"]?["limit"] == ["max": 30, "unit": "characters"])
        let locales = try #require(result["locales"]?.arrayValue)
        #expect(locales.map { $0["code"] } == ["de-DE"])
        #expect(locales[0]["texts"]?["subtitle"] == "Private Notizen, sanfte Fragen")
        let suggestion = try #require(locales[0]["suggestions"]?.arrayValue?.first)
        #expect(suggestion["id"] == .string(open.id))
        #expect(suggestion["value"] == "Neu")
        #expect(suggestion["source"] == "Claude Code")
    }

    @Test func appInformationListsEachPagesFieldsAndChoices() async throws {
        let outcome = try await GetAppInformationTool().call(MCPToolArguments(["appId": "Lumen Information"]), in: context())
        let result = outcome.result
        #expect(result["version"]?["versionString"] == "1.4")
        let pages = try #require(result["pages"]?.arrayValue)
        #expect(pages.map { $0["page"] } == ["general", "review", "ageRating", "accessibility"])
        #expect(pages[0]["fields"]?["copyright"]?["value"] == "© 2026 Northpier Studio")
        #expect(pages[0]["fields"]?["copyright"]?["locked"] == false)
        #expect(pages[1]["fields"]?["notes"]?["limit"] == ["max": 4000, "unit": "characters"])
        let wellness = pages[2]["questions"]?["wellness"]
        #expect(wellness?["value"] == .null)
        #expect(wellness?["answers"] == ["No", "Yes"])
        #expect(wellness?["title"] == "Health or wellness topics")
        #expect(pages[2]["questions"]?["horror"]?["value"] == "None")
        let devices = try #require(pages[3]["devices"]?.arrayValue)
        #expect(devices.map { $0["device"] } == ["iphone", "ipad", "watch", "vision"])
        #expect(devices[0]["features"]?["voiceOver"]?["value"] == "Yes")
        #expect(devices[2]["declared"] == false)
        #expect(devices[2]["features"]?["voiceControl"] == nil)
        #expect(devices[2]["features"]?["voiceOver"]?["answers"] == ["Yes", "No"])
        let categories = try #require(result["choices"]?["categories"]?.arrayValue)
        #expect(categories.contains { $0["id"] == "PRODUCTIVITY" })
        #expect(result["choices"]?["release"]?.arrayValue?.count == ReleaseOption.allCases.count)
    }

    @Test func theSuggestPromptNamesTheAreaAndTheTools() {
        let text = MCPPrompt.suggest.message(app: "Lumen Journal", area: "info")["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(text.contains("App Information and App Review details, from the code"))
        #expect(text.contains("suggest_fields"))
        #expect(text.contains("get_app_information"))
        #expect(MCPPrompt.suggest.requiredTools.isSuperset(of: ["get_store_page", "get_app_information", "suggest_fields"]))
        #expect(MCPPrompt.suggest.json["arguments"]?.arrayValue?.contains { $0["name"] == "area" } == true)
    }
}
#endif
