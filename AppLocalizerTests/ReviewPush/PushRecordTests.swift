//
//  PushRecordTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("PushRecord")
struct PushRecordTests {
    @Test func titlesNameUpToThreeTerritories() {
        let three = ["Mexico", "Türkiye", "India"].map { PushFixtures.price($0) }
        #expect(PushRecord.title(for: three) == "Subscription Pricing · Mexico, Türkiye, India")
        let many = (1...14).map { PushFixtures.price("T\($0)") }
        #expect(PushRecord.title(for: many) == "Subscription Pricing · 14 territories")
    }

    @Test func storePageTitlesCountTextsAndLocales() {
        var french = PushFixtures.listing("Subtitle")
        french.id = "listing.fr.Subtitle"
        french.title = "French · Subtitle"
        let changes = [PushFixtures.listing("Subtitle"), PushFixtures.listing("Keywords"), french]
        #expect(PushRecord.title(for: changes) == "Store Page · 3 texts in 2 locales")
    }

    @Test func mixedSectionsCountChanges() {
        let title = PushRecord.title(for: [PushFixtures.price("BRA"), PushFixtures.listing("Name")])
        #expect(title.hasSuffix("· 2 changes"))
        #expect(title.contains("Subscription Pricing"))
        #expect(title.contains("Store Page"))
    }

    @Test func screenshotTitlesNameOneOrCountThem() {
        #expect(PushRecord.title(for: [PushFixtures.screenshot("German · Slot 3")]) == "Screenshots · German · Slot 3")
        let three = ["German · Slot 1", "German · Slot 2", "French · Slot 1"].map { PushFixtures.screenshot($0) }
        #expect(PushRecord.title(for: three) == "Screenshots · 3 screenshots")
    }

    @Test func mixedSectionsUseFullNamesInShortcutOrder() {
        let changes = [PushFixtures.screenshot("German · Slot 3"), PushFixtures.price("BRA"), PushFixtures.screenshot("German · Slot 4")]
        let names = ["Subscription Pricing", "Screenshots"].formatted(.list(type: .and))
        #expect(PushRecord.title(for: changes) == "\(names) · 3 changes")
    }

    @Test func restoringSwapsValuesAndRequests() throws {
        let pushed = PushFixtures.price("BRA", delta: -50)
        let restored = try #require(pushed.restoring())
        #expect(restored.oldValue == pushed.newValue)
        #expect(restored.newValue == pushed.oldValue)
        #expect(restored.source == .restore)
        #expect(restored.deltaPercent == 100)
        #expect(restored.requests == pushed.restoreRequests)
        #expect(restored.restoreRequests == pushed.requests)
        #expect(PushFixtures.listing("Name").restoring() == nil)

        let record = PushRecord(date: .now, appID: "lumen", appName: "Lumen", title: "", pushed: [pushed, PushFixtures.listing("Name")])
        #expect(record.restoringChanges().map(\.id) == [pushed.id])
    }

    @Test func estimatesCountChecksAndRoundMinutesUp() {
        var checked = PushFixtures.price("BRA")
        checked.conflictCheck = ConflictCheck(path: "/", keyPath: [])
        #expect(PushEstimate(changes: [checked]).requestCount == 2)
        #expect(PushEstimate(changes: [checked]).text == "~2 requests · about 1 min")
        let many = Array(repeating: checked, count: 170)
        #expect(PushEstimate(changes: many).minutes == 6)
        #expect(PushEstimate(changes: Array(repeating: checked, count: 37)).minutes == 2)
    }
}
