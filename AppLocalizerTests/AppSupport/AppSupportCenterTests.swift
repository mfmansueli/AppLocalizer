//
//  AppSupportCenterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Reports, Not Now and what's kept between launches.
@MainActor
@Suite("App support center")
struct AppSupportCenterTests {
    @MainActor
    final class MemoryPersistence: AppSupportPersistence {
        var archive = AppSupportArchive()
        var saves = 0
        func load() -> AppSupportArchive { archive }
        func save(_ archive: AppSupportArchive) {
            self.archive = archive
            saves += 1
        }
    }

    private let appID = "app-1"

    @Test func aReportReplacesTheLastAndIsSaved() {
        let persistence = MemoryPersistence()
        let center = AppSupportCenter(persistence: persistence)
        center.report(AppSupportProfileTests.lumen, for: appID)
        var newer = AppSupportProfileTests.lumen
        newer.languages = [ProjectLanguage(code: "pl")]
        center.report(newer, for: appID)
        #expect(center.profile(for: appID)?.languages.map(\.code) == ["pl"])
        #expect(persistence.saves == 2)
        #expect(AppSupportCenter(persistence: persistence).profile(for: appID) == newer)
    }

    @Test func whatItLearnedIsKeptBetweenLaunches() {
        let persistence = MemoryPersistence()
        let center = AppSupportCenter(persistence: persistence)
        var first = AppKnowledge()
        first.set(.voice, text: "Plain", by: nil, at: .now)
        center.remember(first, for: appID)
        var second = AppKnowledge()
        second.set(.soundMood, text: "Quiet", by: nil, at: .now)
        center.remember(second, for: appID)

        let reopened = AppSupportCenter(persistence: persistence).knowledge(for: appID)
        #expect(reopened?.answer(to: .voice) == "Plain")
        #expect(reopened?.answer(to: .soundMood) == "Quiet")
    }

    @Test func aScanLeavesWhatItLearnedAlone() {
        let center = AppSupportCenter()
        var knowledge = AppKnowledge()
        knowledge.set(.voice, text: "Plain", by: nil, at: .now)
        center.remember(knowledge, for: appID)
        center.report(AppSupportProfileTests.lumen, for: appID)
        #expect(center.knowledge(for: appID)?.answer(to: .voice) == "Plain")
    }

    @Test func anArchiveFromBeforeStillLoads() throws {
        let saved = #"{"profiles":{},"declinedLanguages":{}}"#
        let archive = try JSONDecoder().decode(AppSupportArchive.self, from: Data(saved.utf8))
        #expect(archive.knowledge == nil)
    }

    @Test func notNowHidesALanguageUntilItsUndone() {
        let persistence = MemoryPersistence()
        let center = AppSupportCenter(persistence: persistence, profiles: [appID: AppSupportProfileTests.lumen])
        let store = AppSupportProfileTests.storeLocales
        #expect(center.pendingLanguages(for: appID, storeLocales: store).map(\.code) == ["pl", "tr", "he"])
        center.decline("tr", for: appID)
        #expect(center.pendingLanguages(for: appID, storeLocales: store).map(\.code) == ["pl", "he"])
        #expect(center.missingLanguages(for: appID, storeLocales: store).map(\.code) == ["pl", "tr", "he"])
        #expect(center.isDeclined("tr", for: appID))
        #expect(AppSupportCenter(persistence: persistence).isDeclined("tr", for: appID))
        center.undecline("tr", for: appID)
        #expect(!center.isDeclined("tr", for: appID))
        #expect(center.pendingLanguages(for: appID, storeLocales: store).count == 3)
    }

    @Test func aStoreLocaleFindsItsProjectLanguage() {
        let center = AppSupportCenter(profiles: [appID: AppSupportProfileTests.lumen])
        #expect(center.language(for: appID, storeLocale: "pl")?.coverage == "412 of 418 strings (98%)")
        #expect(center.language(for: appID, storeLocale: "ko") == nil)
        #expect(center.pendingLanguages(for: "other", storeLocales: []).isEmpty)
    }
}
