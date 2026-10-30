//
//  SuggestFieldsToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `suggest_fields` on the fixture Store Page and Lumen's sample App
/// Information: suggestions land in the store per item, refusals say why,
/// `apply` writes changes only with "Suggest and edit drafts", and `total`
/// feeds the Ask request's progress.
@MainActor
@Suite("suggest_fields")
struct SuggestFieldsToolTests {
    private let changes = ChangeQueue()
    private let store = FieldSuggestionStore()
    private let storeApp = StorePageContentFixtures.app
    private let lumen = StoreApp(id: DebugFixtures.AppID.lumen, name: "Lumen Information", bundleID: "dev.example.info", sku: nil, primaryLocale: "en-US")

    private func call(
        _ arguments: [String: JSONValue],
        allowed: Set<MCPProposalKind> = Set(MCPProposalKind.allCases),
        editsDrafts: Bool = false,
        hasStore: Bool = true
    ) async throws -> MCPToolOutcome {
        var workspace = MCPTestFixtures.workspace(
            apps: [storeApp, lumen],
            changes: changes,
            storePage: FakeStorePageServices(),
            appInformation: DebugAppInformationServices()
        )
        workspace.suggestions = hasStore ? store : nil
        var context = MCPToolContext(workspace: workspace, clientName: "Claude Code")
        context.allowedProposals = allowed
        context.editsDrafts = editsDrafts
        return try await SuggestFieldsTool().call(MCPToolArguments(arguments), in: context)
    }

    private func results(_ outcome: MCPToolOutcome) -> [JSONValue] {
        outcome.result["results"]?.arrayValue ?? []
    }

    private func storeItem(_ field: String, _ value: String, locale: String = "en-US") -> JSONValue {
        ["area": "store", "locale": .string(locale), "field": .string(field), "value": .string(value), "reason": "From the commits."]
    }

    @Test func aStorePageItemWaitsAsASuggestion() async throws {
        let outcome = try await call([
            "appId": "Lumen Journal",
            "items": [[
                "locale": "en-US", "field": "whatsNew", "value": "• Weekly reflections", "reason": "From v1.3..HEAD.",
                "evidence": [["kind": "git", "ref": "v1.3..4f2c91a"]],
            ]],
        ])
        let result = try #require(results(outcome).first)
        #expect(result["status"] == "queued")
        #expect(result["locale"] == "en-US")
        let suggestion = try #require(store.all(for: storeApp.id).first)
        #expect(suggestion.target == .storePage(.englishUS, .whatsNew))
        #expect(suggestion.source == .assistant(client: "Claude Code"))
        #expect(suggestion.evidence == [SuggestionEvidence(kind: "git", ref: "v1.3..4f2c91a")])
        #expect(result["id"] == .string(suggestion.id))
        #expect(outcome.result["queued"] == 1)
        #expect(outcome.logLines.first?.outcome == .proposed)
        #expect(changes.changes.isEmpty)
    }

    @Test func theFieldsOwnValueIsUnchangedAndANewerOneReplaces() async throws {
        let same = try await call(["appId": "app1", "items": [storeItem("subtitle", "Private notes, gentle prompts")]])
        #expect(results(same).first?["status"] == "unchanged")
        _ = try await call(["appId": "app1", "items": [storeItem("subtitle", "Private diary & prompts")]])
        let newer = try await call(["appId": "app1", "items": [storeItem("subtitle", "Private diary, mood & prompts")]])
        #expect(results(newer).first?["status"] == "replaced")
        #expect(store.all(for: storeApp.id).map(\.value) == ["Private diary, mood & prompts"])
    }

    @Test func refusalsSayWhy() async throws {
        let outcome = try await call(["appId": "app1", "items": [
            storeItem("subtitle", String(repeating: "a", count: 34)),
            storeItem("tagline", "Hi"),
            storeItem("whatsNew", "Neu", locale: "fr-FR"),
            storeItem("supportUrl", "lumen.example"),
        ]])
        let items = results(outcome)
        #expect(items.map { $0["code"] } == ["over_limit", "unknown_field", "unknown_locale", "invalid_value"])
        #expect(items[0]["count"] == 34)
        #expect(items[0]["status"] == "refused")
        #expect(outcome.result["refused"] == 4)
        #expect(outcome.logLines.allSatisfy { $0.outcome == .refused })
        #expect(store.suggestions.isEmpty)
    }

    @Test func permissionsAreCheckedPerArea() async throws {
        let outcome = try await call(["appId": "app1", "items": [storeItem("whatsNew", "New")]], allowed: [.appInformation])
        #expect(results(outcome).first?["code"] == "not_permitted")
    }

    @Test func anotherVersionIsRefusedWhole() async {
        await #expect(throws: MCPToolError.self) {
            try await call(["appId": "app1", "version": "1.9", "items": [storeItem("whatsNew", "New")]])
        }
    }

    @Test func withoutTheStoreItsUnavailable() async {
        await #expect(throws: MCPToolError.self) {
            try await call(["appId": "app1", "items": [storeItem("whatsNew", "New")]], hasStore: false)
        }
    }

    @Test func applyWritesAChangeOnlyWhenDraftsMayBeEdited() async throws {
        let waiting = try await call(["appId": "app1", "apply": true, "items": [storeItem("whatsNew", "Waiting")]])
        #expect(results(waiting).first?["status"] == "queued")
        #expect(results(waiting).first?["note"] != nil)
        #expect(changes.changes.isEmpty)

        let applied = try await call(["appId": "app1", "apply": true, "items": [storeItem("whatsNew", "Applied")]], editsDrafts: true)
        #expect(results(applied).first?["status"] == "applied")
        let change = try #require(changes.change(id: StorePageContentFixtures.changeID(.englishUS, .whatsNew)))
        #expect(change.newValue == "Applied")
        #expect(change.source == .assistant(client: "Claude Code"))
    }

    @Test func totalFeedsTheAskRequest() async throws {
        store.beginRequest(appID: storeApp.id, area: .storePage, client: "Claude Code", prompt: "Suggest…")
        _ = try await call(["appId": "app1", "total": 3, "items": [storeItem("whatsNew", "One")]])
        #expect(store.request?.total == 3)
        #expect(store.request?.received == 1)
    }

    @Test func appInformationItemsAreStoredAsAppStoreConnectIDs() async throws {
        let outcome = try await call(["appId": "Lumen Information", "items": [
            ["area": "info", "page": "general", "field": "secondaryCategory", "value": "Productivity", "reason": "No health features."],
            ["page": "review", "field": "notes", "value": "Settings → Debug → Add Sample Week."],
            ["page": "general", "field": "primaryCategory", "value": "Gardening"],
            ["page": "review", "field": "copyright", "value": "© 2027"],
        ]])
        let items = results(outcome)
        #expect(items.map { $0["status"] } == ["queued", "queued", "refused", "refused"])
        #expect(items[2]["code"] == "invalid_value")
        #expect(items[3]["code"] == "unknown_field")
        #expect(items[1]["page"] == "review")
        let values = Dictionary(uniqueKeysWithValues: store.all(for: lumen.id).map { ($0.target, $0.value) })
        #expect(values[.appInformation(.secondaryCategory)] == "PRODUCTIVITY")
        #expect(values[.appInformation(.notes)] == "Settings → Debug → Add Sample Week.")
    }

    @Test func applyingAppInformationQueuesItsChange() async throws {
        let outcome = try await call(
            ["appId": "Lumen Information", "apply": true, "items": [["page": "general", "field": "copyright", "value": "© 2027 Northpier Studio"]]],
            editsDrafts: true
        )
        let result = try #require(results(outcome).first)
        #expect(result["status"] == "applied")
        let changeID = try #require(result["changeId"]?.stringValue)
        let change = try #require(changes.change(id: changeID))
        #expect(change.newValue == "© 2027 Northpier Studio")
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(store.suggestions.isEmpty)
    }

    @Test func ageRatingAnswersAreStoredByID() async throws {
        let outcome = try await call(["appId": "Lumen Information", "items": [
            ["area": "info", "page": "ageRating", "field": "wellness", "value": "Yes", "reason": "Mood tracking."],
            ["page": "age_rating", "field": "horror", "value": "Infrequent"],
            ["page": "ageRating", "field": "webAccess", "value": "Maybe"],
            ["page": "ageRating", "field": "copyright", "value": "No"],
        ]])
        let items = results(outcome)
        #expect(items.map { $0["status"] } == ["queued", "queued", "refused", "refused"])
        #expect(items[2]["code"] == "invalid_answer")
        #expect(items[2]["reason"] == "“Maybe” isn’t an answer to webAccess. The answers are No, Yes.")
        #expect(items[3]["code"] == "unknown_field")
        #expect(items[0]["page"] == "ageRating")
        let values = Dictionary(uniqueKeysWithValues: store.all(for: lumen.id).map { ($0.target, $0.value) })
        #expect(values[AppInformationSuggestionSlot.ageRating(.wellness).target] == "affirmative")
        #expect(values[AppInformationSuggestionSlot.ageRating(.horror).target] == "infrequent")
        #expect(outcome.logLines.first?.target == "Lumen Information · Age Rating · Health or wellness topics")
    }

    @Test func accessibilityFeaturesNeedADeviceTheAppRunsOn() async throws {
        let outcome = try await call(["appId": "Lumen Information", "items": [
            ["page": "accessibility", "device": "watch", "field": "voiceOver", "value": "yes"],
            ["page": "accessibility", "device": "Apple Watch", "field": "voiceControl", "value": "yes"],
            ["page": "accessibility", "field": "largerText", "value": "yes"],
            ["page": "accessibility", "device": "tv", "field": "largerText", "value": "yes"],
            ["page": "accessibility", "device": "iphone", "field": "voiceOver", "value": "yes"],
            ["page": "accessibility", "device": "iphone", "field": "reducedMotion", "value": "sometimes"],
        ]])
        let items = results(outcome)
        #expect(items.map { $0["status"] } == ["queued", "refused", "refused", "refused", "unchanged", "refused"])
        #expect(items.map { $0["code"] } == [nil, "unknown_field", "invalid_value", "invalid_value", nil, "invalid_answer"])
        #expect(items[0]["device"] == "watch")
        #expect(items[0]["page"] == "accessibility")
        let suggestion = try #require(store.all(for: lumen.id).first)
        #expect(suggestion.target == AppInformationSuggestionSlot.accessibility(.appleWatch, .voiceOver).target)
        #expect(suggestion.value == "yes")
        #expect(outcome.logLines.first?.target == "Lumen Information · Accessibility · Apple Watch · VoiceOver")
    }

    @Test func applyingTwoFeaturesOfADeviceQueuesOneDeclarationWithBoth() async throws {
        let outcome = try await call(
            ["appId": "Lumen Information", "apply": true, "items": [
                ["page": "accessibility", "device": "watch", "field": "voiceOver", "value": "yes"],
                ["page": "accessibility", "device": "watch", "field": "largerText", "value": "yes"],
            ]],
            editsDrafts: true
        )
        #expect(results(outcome).map { $0["status"] } == ["applied", "applied"])
        let change = try #require(changes.changes.first)
        #expect(changes.changes.count == 1)
        #expect(change.source == .assistant(client: "Claude Code"))
        #expect(change.newValue == AccessibilityAnswer(features: [.voiceOver, .largerText]).summary)
        #expect(store.suggestions.isEmpty)
    }

    @Test func anAppliedAnswerWaitsForConfirmed() async throws {
        let outcome = try await call(
            ["appId": "Lumen Information", "apply": true, "items": [["page": "ageRating", "field": "wellness", "value": "Yes"]]],
            editsDrafts: true
        )
        #expect(results(outcome).first?["status"] == "applied")
        let builder = AppInformationChangeBuilder(appID: lumen.id, ids: DebugAppInformationContent.lumen(versionID: nil).ids, versionString: nil)
        #expect(builder.assistantAnswers(in: changes.changes)[.wellness]?.confirmed == false)
    }
}
#endif
