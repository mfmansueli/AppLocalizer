//
//  SuggestionsSummaryTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The overview's Suggestions card: counts by area, language and source.
@Suite("SuggestionsSummary")
struct SuggestionsSummaryTests {
    private func suggestion(_ target: SuggestionTarget, _ source: SuggestionSource, at seconds: TimeInterval = 0) -> FieldSuggestion {
        FieldSuggestion(
            id: UUID().uuidString,
            appID: "1",
            target: target,
            value: "x",
            reason: "",
            source: source,
            createdAt: Date(timeIntervalSince1970: seconds)
        )
    }

    @Test func countsByAreaLanguageAndSource() {
        let summary = SuggestionsSummary(open: [
            suggestion(.storePage(.englishUS, .whatsNew), .assistant(client: "Claude Code"), at: 1),
            suggestion(.storePage(.german, .whatsNew), .assistant(client: "Cursor"), at: 2),
            suggestion(.storePage(.german, .keywords), .aiProvider),
            suggestion(.appInformation(.copyright), .builtIn),
        ])
        #expect(summary.total == 4)
        #expect(summary.pillText == "4 to review")
        #expect(summary.storePageText == "3 · German 2 · English (U.S.) 1")
        #expect(summary.appInformationText == "1")
        #expect(summary.sourcesText(assistant: nil) == "Built-in 1 · Cursor 2 · AI provider 1")
    }

    @Test func nothingOpenSaysSo() {
        let summary = SuggestionsSummary(open: [])
        #expect(summary.pillText == "All reviewed")
        #expect(summary.storePageText == "None")
        #expect(summary.appInformationText == "None")
        #expect(summary.sourcesText(assistant: "Claude Code") == "Built-in 0 · Claude Code 0 · AI provider 0")
        #expect(summary.sourcesText(assistant: nil) == "Built-in 0 · Assistant 0 · AI provider 0")
    }
}
