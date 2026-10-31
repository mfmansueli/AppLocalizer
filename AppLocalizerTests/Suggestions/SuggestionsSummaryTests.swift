//
//  SuggestionsSummaryTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The overview's Suggestions card: counts by page and source, what's
/// still coming from Suggest Everything, and locked pages.
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

    @Test func countsByPageAndSource() {
        let summary = SuggestionsSummary(open: [
            suggestion(.storePage(.englishUS, .whatsNew), .assistant(client: "Claude Code"), at: 1),
            suggestion(.storePage(.german, .whatsNew), .assistant(client: "Cursor"), at: 2),
            suggestion(.storePage(.german, .keywords), .aiProvider),
            suggestion(.appInformation(.copyright), .builtIn),
            suggestion(AppInformationSuggestionSlot.ageRating(.wellness).target, .builtIn),
            suggestion(AppInformationSuggestionSlot.accessibility(.appleWatch, .voiceOver).target, .assistant(client: "Cursor")),
        ])
        #expect(summary.total == 6)
        #expect(summary.pillText == "6 to review")
        #expect(SuggestionPage.allCases.map(summary.count(on:)) == [3, 1, 1, 1, 0])
        #expect(summary.text(on: .storePage) == "3")
        #expect(summary.text(on: .appReview) == "None")
        #expect(summary.sourcesText(assistant: nil) == "Built-in 2 · Cursor 3 · AI provider 1")
    }

    @Test func suggestEverythingSaysWhatsComingAndWhatsLocked() {
        let summary = SuggestionsSummary(open: [suggestion(.storePage(.englishUS, .whatsNew), .builtIn)])
        #expect(summary.text(on: .storePage, coming: 2) == "1 · 2 coming")
        #expect(summary.text(on: .ageRating, coming: 4) == "0 · 4 coming")
        #expect(summary.text(on: .appReview, isLocked: true) == "Locked")
        #expect(summary.text(on: .storePage, isLocked: true) == "1")
    }

    @Test func nothingOpenSaysSo() {
        let summary = SuggestionsSummary(open: [])
        #expect(summary.pillText == "All reviewed")
        #expect(summary.text(on: .storePage) == "None")
        #expect(summary.text(on: .general) == "None")
        #expect(summary.sourcesText(assistant: "Claude Code") == "Built-in 0 · Claude Code 0 · AI provider 0")
        #expect(summary.sourcesText(assistant: nil) == "Built-in 0 · Assistant 0 · AI provider 0")
    }
}
