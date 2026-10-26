//
//  KeyAccessCheckTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("KeyAccessCheck")
struct KeyAccessCheckTests {
    private func check(apps: Int, sales: SalesAccess = .readable) -> KeyAccessCheck {
        KeyAccessCheck(appCount: apps, milliseconds: 182, salesAccess: sales, date: Date(timeIntervalSince1970: 0))
    }

    @Test func connectionSummaryCountsAppsAndTime() {
        #expect(check(apps: 6).connectionSummary == "Connected · 6 apps · 182 ms")
        #expect(check(apps: 1).connectionSummary == "Connected · 1 app · 182 ms")
    }

    @Test func salesSummarySaysWhatSuggestionsCanUse() {
        #expect(check(apps: 6).salesSummary.contains("read Sales and Trends"))
        #expect(check(apps: 6, sales: .notAllowed).salesSummary.contains("purchasing power only"))
        #expect(check(apps: 6, sales: .unknown).salesSummary.contains("Couldn’t check"))
    }

    @Test func roundTripsThroughJSON() throws {
        let original = check(apps: 3, sales: .notAllowed)
        let decoded = try JSONDecoder().decode(KeyAccessCheck.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
