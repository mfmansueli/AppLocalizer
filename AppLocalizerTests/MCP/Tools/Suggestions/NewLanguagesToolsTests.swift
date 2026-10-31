//
//  NewLanguagesToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Languages the app's project has and its App Store page doesn't, over
/// MCP: the read tools list them, `suggest_fields` takes them as locales,
/// and nothing creates a page but the person.
@MainActor
@Suite("New languages over MCP")
struct NewLanguagesToolsTests {
    private let changes = ChangeQueue()
    private let store = FieldSuggestionStore()

    private func context(center: AppSupportCenter = NewLanguagesFixtures.center(), editsDrafts: Bool = false) -> MCPToolContext {
        var workspace = MCPTestFixtures.workspace(
            apps: [StorePageContentFixtures.app],
            changes: changes,
            storePage: NewLanguagesFixtures.services(center)
        )
        workspace.suggestions = store
        var context = MCPToolContext(workspace: workspace, clientName: "Claude Code")
        context.editsDrafts = editsDrafts
        return context
    }

    private func suggest(_ items: [JSONValue], apply: Bool = false, in context: MCPToolContext) async throws -> [JSONValue] {
        let outcome = try await SuggestFieldsTool().call(MCPToolArguments(["appId": "app1", "apply": .bool(apply), "items": .array(items)]), in: context)
        return outcome.result["results"]?.arrayValue ?? []
    }

    private func item(_ field: String, _ value: String, locale: String) -> JSONValue {
        ["area": "store", "locale": .string(locale), "field": .string(field), "value": .string(value), "reason": "Translated."]
    }

    @Test func theStorePageListsTheLanguagesTheAppStoreLacks() async throws {
        let outcome = try await GetStorePageTool().call(MCPToolArguments(["appId": "app1"]), in: context(center: NewLanguagesFixtures.center(declined: ["he"])))
        let locales = try #require(outcome.result["locales"]?.arrayValue)
        #expect(locales.map { $0["code"] } == ["en-US", "de-DE", "pl", "tr"])
        #expect(locales[2]["new"] == true)
        #expect(locales[2]["texts"] == [:])
        #expect(locales[0]["new"] == nil)
        let missing = try #require(outcome.result["languagesNotOnAppStore"]?.arrayValue)
        #expect(missing.map { $0["code"] } == ["pl", "tr", "he"])
        #expect(missing.map { $0["status"] } == ["suggested", "suggested", "notNow"])
        #expect(missing[0]["translated"] == "412 of 418 strings (98%)")
        #expect(missing[0]["source"] == "Localizable.xcstrings")
        #expect(missing[2]["note"] == "Right to left; tested in LumenUITests")
    }

    @Test func theListingListsThemWithoutAddingThemToItsLocales() async throws {
        let outcome = try await GetListingTool().call(MCPToolArguments(["appId": "app1"]), in: context())
        #expect(outcome.result["locales"]?.arrayValue?.map { $0["code"] } == ["en-US", "de-DE"])
        #expect(outcome.result["languagesNotOnAppStore"]?.arrayValue?.count == 3)

        let polish = try await GetListingTool().call(MCPToolArguments(["appId": "app1", "locales": ["pl"]]), in: context())
        #expect(polish.result["locales"]?.arrayValue?.first?["new"] == true)
    }

    @Test func aSuggestionForANewLanguageWaitsInItsTab() async throws {
        let results = try await suggest([item("subtitle", "Dziennik nastroju", locale: "pl")], in: context())
        let result = try #require(results.first)
        #expect(result["status"] == "queued")
        #expect(result["note"]?.stringValue?.hasPrefix("Polish isn’t on the App Store yet") == true)
        #expect(store.all(for: "app1").map(\.target) == [.storePage(.polish, .subtitle)])
        #expect(changes.changes.isEmpty)
    }

    @Test func applyNeverCreatesAPage() async throws {
        let results = try await suggest([item("subtitle", "Dziennik nastroju", locale: "pl")], apply: true, in: context(editsDrafts: true))
        #expect(results.first?["status"] == "queued")
        #expect(changes.changes.isEmpty)
        #expect(store.all(for: "app1").count == 1)
    }

    @Test func aLanguageSaidNotNowToIsRefused() async throws {
        let results = try await suggest([item("subtitle", "יומן", locale: "he")], in: context(center: NewLanguagesFixtures.center(declined: ["he"])))
        #expect(results.first?["code"] == "unknown_locale")
        #expect(results.first?["reason"]?.stringValue?.contains("Not Now") == true)
        #expect(store.suggestions.isEmpty)
    }

    @Test func anUnknownLocaleNamesTheNewLanguagesToo() async throws {
        let results = try await suggest([item("subtitle", "Notes", locale: "fr-FR")], in: context())
        #expect(results.first?["code"] == "unknown_locale")
        #expect(results.first?["reason"]?.stringValue?.hasSuffix("the app also supports pl, tr, he, which aren’t on the App Store yet.") == true)
    }

    @Test func anAddedLanguageTakesAppliedValues() async throws {
        let center = NewLanguagesFixtures.center()
        var builder = ListingChangeBuilder(appID: "app1", ids: StorePageContentFixtures.ids, versionString: "2.0")
        builder.newPages = [.polish, .turkish, .hebrew]
        var listing = StorePageContentFixtures.editable.listing()
        listing.addLocale(.polish)
        changes.upsert(contentsOf: builder.changes(for: listing))

        let results = try await suggest([item("subtitle", "Dziennik nastroju", locale: "pl")], apply: true, in: context(center: center, editsDrafts: true))
        #expect(results.first?["status"] == "applied")
        #expect(results.first?["note"] == nil)
        let created = try #require(changes.change(id: "storePage.app1.appInfo.info.pl.new"))
        #expect(created.creation?.title == "Create the Polish page")
    }
}
#endif
