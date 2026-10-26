//
//  AppSearchTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("AppSearch")
struct AppSearchTests {
    private let apps = [
        StoreApp(id: "1", name: "Bruma", bundleID: "com.lima.bruma", sku: "BRUMA2024"),
        StoreApp(id: "2", name: "Receitas da Vó", bundleID: "com.lima.receitas"),
        StoreApp(id: "3", name: "Focus Timer", bundleID: "io.focus.timer"),
    ]

    private func names(_ query: String) -> [String] {
        AppSearch.filter(apps, matching: query).map(\.name)
    }

    @Test(arguments: ["", "   "])
    func blankQueryKeepsEverything(query: String) {
        #expect(names(query) == ["Bruma", "Receitas da Vó", "Focus Timer"])
    }

    @Test func matchesNameIgnoringCaseAndDiacritics() {
        #expect(names("receitas da vo") == ["Receitas da Vó"])
        #expect(names("BRUMA") == ["Bruma"])
    }

    @Test func matchesBundleIDAndSKU() {
        #expect(names("io.focus") == ["Focus Timer"])
        #expect(names("2024") == ["Bruma"])
    }

    @Test func everyWordHasToMatch() {
        #expect(names("lima receitas") == ["Receitas da Vó"])
        #expect(names("lima timer").isEmpty)
    }

    @Test func keepsTheOriginalOrder() {
        #expect(names("com.lima") == ["Bruma", "Receitas da Vó"])
    }
}
