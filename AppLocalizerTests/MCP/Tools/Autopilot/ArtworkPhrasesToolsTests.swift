//
//  ArtworkPhrasesToolsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The assistant translates the pages' phrases at Localize: next_step's
/// write_artwork_texts gives each one with its language, and
/// propose_captions saves its words right away (placement text), only for
/// a phrase the pages write.
@MainActor
@Suite("The pages' phrases over MCP", .serialized)
struct ArtworkPhrasesToolsTests {
    private static let phrase = StudioDebugWebArtwork.phrase

    /// Localizing in English and German, with Quiet Indigo's phrase on
    /// the search page and German's words still to write.
    private var localizing: AutopilotRun {
        var run = StudioDebugExtras.run(.localize)
        run.plan.localeCodes = ["en-US", "de-DE"]
        run.overflows = []
        run.shortenings = []
        for index in run.directions.indices { run.directions[index].artworkDesign = StudioDebugWebArtwork.withPhrase }
        run.artworkTextNeeds = [AutopilotArtworkTextNeed(locale: "de-DE", role: .search, problem: .missing, phrase: Self.phrase)]
        return run
    }

    @Test func nextStepAsksForThePhraseInEachLanguage() async throws {
        let outcome = try await MCPAutopilotFixtures(localizing).call(NextStepTool(), ["run": "run-debug"])
        #expect(outcome.result["action"] == "write_artwork_texts")
        let item = try #require(outcome.result["texts"]?.arrayValue?.first)
        #expect(item == ["locale": "de-DE", "placement": "text", "phrase": "Small steps count.", "problem": "missing", "on": "search"])
    }

    @Test func aPhrasesWordsAreSavedRightAway() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        let outcome = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "The search page's phrase.",
            "items": [["locale": "de", "placement": "text", "phrase": "Small  steps count.", "headline": " Kleine  Schritte zählen. "]],
        ])
        #expect(outcome.result["status"] == "saved", "\(outcome.result)")
        #expect(outcome.result["saved"] == 1)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · de-DE · “Small steps count.”", outcome: .proposed)])
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.artworkTexts?.phrase(Self.phrase, locale: "de-DE") == ScreenshotCaption(
            headline: "Kleine Schritte zählen.", subhead: nil, provenance: .assistant(client: "Claude Code", date: AutopilotTestFixtures.now)
        ))
        #expect(document.artworkTexts?.headline(.search, locale: "de-DE") != "Kleine Schritte zählen.", "Not the search headline")
        #expect(fixtures.run?.log.contains { $0.text == "Claude Code translated 1 phrase into de-DE" } == true)
    }

    @Test func aShorterPhraseInThePrimaryLanguageIsKept() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        let outcome = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "Too long.",
            "items": [["locale": "en-US", "placement": "text", "phrase": .string(Self.phrase), "headline": "Small steps."]],
        ])
        #expect(outcome.result["status"] == "saved", "\(outcome.result)")
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.artworkTexts?.phrase(Self.phrase, locale: "en-US")?.headline == "Small steps.")
    }

    @Test func onlyThePagesPhrasesAreSaved() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        let unknown = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "x", "items": [["locale": "de-DE", "placement": "text", "phrase": "Big leaps", "headline": "Große Sprünge"]],
        ])
        #expect(unknown.result["status"] == "refused")
        let reason = unknown.result["reason"]?.stringValue ?? ""
        #expect(reason.contains("must be one of the pages’ phrases, exactly as next_step gave it: “Small steps count.”"), "\(reason)")

        let empty = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "x", "items": [["locale": "de-DE", "placement": "text", "phrase": .string(Self.phrase), "headline": "  "]],
        ])
        #expect(empty.result["reason"] == "A text item needs the phrase’s words in de-DE as headline.")

        let elsewhere = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "x", "items": [["locale": "ja", "placement": "text", "phrase": .string(Self.phrase), "headline": "小さな一歩"]],
        ])
        #expect(elsewhere.result["reason"] == "A text item needs a locale of the plan.")
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.artworkTexts?.phrases == nil, "Nothing was saved")
    }

    @Test func theToolSaysHowToSendAPhrase() {
        let definition = ProposeCaptionsTool().definition
        #expect(definition.description.contains("For placement text, add phrase"))
        let properties = definition.inputSchema["properties"]?["items"]?["items"]?["properties"]
        #expect(properties?["placement"]?["enum"] == ["search", "header", "text"])
        #expect(properties?["phrase"] != nil)
    }
}
#endif
