//
//  SuggestionBarModelTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The suggestion bar's words and counts.
@Suite("SuggestionBarModel")
struct SuggestionBarModelTests {
    private func model(
        open: Int,
        total: Int,
        counts: [SuggestionSourceFilter: Int] = [:],
        filter: SuggestionSourceFilter = .all,
        everywhere: Int = 0
    ) -> SuggestionBarModel {
        SuggestionBarModel(
            openCount: open,
            totalCount: total,
            countsBySource: counts,
            assistantName: "Claude Code",
            filter: filter,
            dismissedCount: 0,
            everywhereCount: everywhere
        )
    }

    @Test func theCountSaysWhatsLeft() {
        #expect(model(open: 1, total: 1).countText == "1 suggestion")
        #expect(model(open: 5, total: 6).countText == "5 suggestions")
        #expect(model(open: 0, total: 3).countText == "All suggestions reviewed")
        #expect(model(open: 0, total: 0).countText == "No suggestions")
        #expect(!model(open: 0, total: 0).hasSecondLine)
    }

    @Test func emptySourcesHideButTheAssistantAndTheChosenOneStay() {
        let bar = model(open: 2, total: 2, counts: [.builtIn: 2, .assistant: 0, .aiProvider: 0], filter: .aiProvider)
        #expect(bar.segments == [.all, .builtIn, .assistant, .aiProvider])
        let plain = model(open: 2, total: 2, counts: [.builtIn: 2])
        #expect(plain.segments == [.all, .builtIn, .assistant])
        #expect(plain.segmentTitle(.assistant) == "Claude Code 0")
        #expect(plain.segmentTitle(.all) == "All 2")
    }

    @Test func acceptAllTakesWhatTheFilterShows() {
        let bar = model(open: 5, total: 5, counts: [.builtIn: 2, .assistant: 3], filter: .assistant, everywhere: 9)
        #expect(bar.visibleCount == 3)
        #expect(bar.otherScopesCount == 6)
    }
}
