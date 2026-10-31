//
//  SuggestionRunToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A Suggest Everything run over MCP: `begin_suggestions` takes the plan and
/// says what it skipped, `suggest_fields` with the run fills it in, Stop
/// Receiving refuses the rest, and `end_suggestions` finishes it.
@MainActor
@Suite("begin_suggestions and end_suggestions")
struct SuggestionRunToolsTests {
    private let changes = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let storeApp = StorePageContentFixtures.app
    private let lumen = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Information", bundleID: "dev.example.info", sku: nil, primaryLocale: "en-US")

    private func context(editsDrafts: Bool = false) -> MCPToolContext {
        var workspace = MCPTestFixtures.workspace(
            apps: [storeApp, lumen],
            changes: changes,
            storePage: FakeStorePageServices(),
            appInformation: DebugAppInformationServices()
        )
        workspace.suggestions = store
        var context = MCPToolContext(workspace: workspace, clientName: "Claude Code")
        context.editsDrafts = editsDrafts
        return context
    }

    private func begin(_ plan: [JSONValue], app: String = "app1") async throws -> MCPToolOutcome {
        try await BeginSuggestionsTool().call(MCPToolArguments(["appId": .string(app), "plan": .array(plan)]), in: context())
    }

    private func suggest(_ items: [JSONValue], run: String?, editsDrafts: Bool = false) async throws -> [JSONValue] {
        var arguments: [String: JSONValue] = ["appId": "app1", "items": .array(items)]
        if let run { arguments["run"] = .string(run) }
        if editsDrafts { arguments["apply"] = true }
        let outcome = try await SuggestFieldsTool().call(MCPToolArguments(arguments), in: context(editsDrafts: editsDrafts))
        return outcome.result["results"]?.arrayValue ?? []
    }

    private func entry(_ field: String, locale: String = "en-US") -> JSONValue {
        ["area": "store", "locale": .string(locale), "field": .string(field)]
    }

    private func item(_ field: String, _ value: String) -> JSONValue {
        ["area": "store", "locale": "en-US", "field": .string(field), "value": .string(value), "reason": "From CHANGELOG.md."]
    }

    @Test func thePlanStartsARunAndSaysWhatItSkipped() async throws {
        store.add(appID: storeApp.id, target: .storePage(.englishUS, .keywords), value: "journal,mood", reason: "", source: .assistant(client: "Claude Code"))
        store.beginRequest(appID: storeApp.id, area: .storePage, client: "Claude Code", prompt: "Suggest Store Page text…")

        let outcome = try await begin([
            entry("description"),
            entry("keywords"),
            entry("whatsNew"),
            entry("tagline"),
            entry("whatsNew", locale: "fr-FR"),
        ])
        #expect(outcome.result["run"] == "run_1")
        #expect(outcome.result["accepted"] == 1)
        let skipped = try #require(outcome.result["skipped"]?.arrayValue)
        #expect(skipped.map { $0["code"] } == ["already_suggested", "in_another_request", "unknown_field", "unknown_locale"])
        #expect(skipped[0]["field"] == "keywords")
        #expect(skipped[0]["locale"] == "en-US")
        #expect(store.run?.plan == [.storePage(.englishUS, .description)])
        #expect(store.run?.phase == .running)
    }

    @Test func fieldsThePersonChangedAreLeftAlone() async throws {
        _ = try await suggest([item("whatsNew", "Typed by hand")], run: nil, editsDrafts: true)
        let outcome = try await begin([entry("whatsNew"), entry("description")])
        #expect(outcome.result["skipped"]?.arrayValue?.first?["code"] == "changed_by_you")
        #expect(outcome.result["accepted"] == 1)
    }

    @Test func appInformationPlansNameQuestionsAndFeatures() async throws {
        let outcome = try await begin([
            ["area": "info", "page": "general", "field": "secondaryCategory"],
            ["area": "info", "page": "ageRating", "field": "wellness"],
            ["area": "info", "page": "accessibility", "device": "watch", "field": "voiceOver"],
            ["area": "info", "page": "accessibility", "device": "tv", "field": "voiceOver"],
        ], app: "Lumen Information")
        #expect(outcome.result["accepted"] == 3)
        #expect(outcome.result["skipped"]?.arrayValue?.first?["code"] == "invalid_value")
        #expect(store.run?.plan.last == AppInformationSuggestionSlot.accessibility(.appleWatch, .voiceOver).target)
    }

    @Test func suggestionsWithTheRunFillItInAndEndingFinishesIt() async throws {
        let run = try #require(try await begin([entry("description"), entry("promotionalText")]).result["run"]?.stringValue)
        let first = try await suggest([item("description", "A calm place to write.")], run: run)
        #expect(first.first?["status"] == "queued")
        #expect(store.run?.received == 1)

        _ = try await suggest([item("keywords", "journal,mood,reflection")], run: run)
        #expect(store.run?.total == 3)
        #expect(store.run?.received == 2)

        let ended = try await EndSuggestionsTool().call(MCPToolArguments(["run": .string(run)]), in: context())
        #expect(ended.result["status"] == "finished")
        #expect(ended.result["received"] == 2)
        #expect(ended.result["total"] == 3)
        #expect(store.run?.phase == .finished)
    }

    @Test func afterStopReceivingTheRunsCallsAreRefused() async throws {
        let run = try #require(try await begin([entry("description")]).result["run"]?.stringValue)
        store.stopRun()
        let results = try await suggest([item("description", "A calm place to write.")], run: run)
        #expect(results.first?["code"] == "run_stopped")
        #expect(store.all(for: storeApp.id).isEmpty)

        let ended = try await EndSuggestionsTool().call(MCPToolArguments(["run": .string(run)]), in: context())
        #expect(ended.result["status"] == "stopped")
    }

    @Test func endingARunThatIsntGoingOnIsNotFound() async {
        await #expect(throws: MCPToolError.self) {
            try await EndSuggestionsTool().call(MCPToolArguments(["run": "run_7"]), in: context())
        }
    }

    @Test func suggestAllNamesTheRunsTools() {
        let text = MCPPrompt.suggestAll.message(app: "Lumen Journal")["messages"]?.arrayValue?.first?["content"]?["text"]?.stringValue ?? ""
        #expect(text.hasPrefix("Suggest everything for the app “Lumen Journal” in AppLocalizer"))
        #expect(text.contains("begin_suggestions"))
        #expect(text.contains("run_stopped"))
        #expect(text.contains("report_app_support first"))
        #expect(text.contains("including languages the app supports that aren’t on the App Store yet"))
        #expect(text.contains("languagesNotOnAppStore"))
        #expect(MCPPrompt.suggestAll.slashCommand == "/mcp__applocalizer__suggest_all")
        #expect(MCPPrompt.suggestAll.json["arguments"]?.arrayValue?.count == 1)
    }
}
#endif
