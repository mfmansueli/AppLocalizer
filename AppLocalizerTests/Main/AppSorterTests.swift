//
//  AppSorterTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("AppSorter")
struct AppSorterTests {
    private let apps = [
        StoreApp(id: "t", name: "Tempo", bundleID: "t"),
        StoreApp(id: "l", name: "Lumen", bundleID: "l"),
        StoreApp(id: "f", name: "fieldnote", bundleID: "f"),
        StoreApp(id: "q", name: "Quiet", bundleID: "q"),
    ]

    private let indicators: [String: AppIndicators] = [
        "t": AppIndicators(pendingChangeCount: 0, localeCount: 39, priceSuggestionCount: nil),
        "l": AppIndicators(pendingChangeCount: 2, localeCount: 10, priceSuggestionCount: 146),
        "f": AppIndicators(pendingChangeCount: 2, localeCount: 6, priceSuggestionCount: 148),
        "q": AppIndicators(pendingChangeCount: 0, localeCount: nil, priceSuggestionCount: nil),
    ]

    private func sorted(_ order: AppSortOrder) -> [String] {
        AppSorter.sort(apps, by: order) { indicators[$0.id] ?? AppIndicators() }.map(\.id)
    }

    @Test func nameIgnoresCase() {
        #expect(sorted(.name) == ["f", "l", "q", "t"])
    }

    @Test func unpushedChangesFirstThenByName() {
        #expect(sorted(.unpushedChanges) == ["f", "l", "q", "t"])
    }

    @Test func lowestCoverageFirstAndUnknownLast() {
        #expect(sorted(.lowestCoverage) == ["f", "l", "t", "q"])
    }

    @Test func mostSuggestionsFirstAndHiddenOnesLast() {
        #expect(sorted(.mostSuggestions) == ["f", "l", "q", "t"])
    }
}
