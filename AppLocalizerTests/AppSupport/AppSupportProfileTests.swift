//
//  AppSupportProfileTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What a project supports compared with the App Store page.
@Suite("App support profile")
struct AppSupportProfileTests {
    static let storeLocales = ["en-US", "de-DE", "ja", "ar-SA"]

    static let lumen = AppSupportProfile(
        targets: ["Lumen (iOS, visionOS)", "LumenWatch Watch App"],
        devices: [
            SupportedDevice(displayType: .iPad, reason: "Lumen runs on iPad"),
            SupportedDevice(displayType: .watch, reason: "Lumen has a watch app, LumenWatch"),
        ],
        languages: [
            ProjectLanguage(code: "en"), ProjectLanguage(code: "de"), ProjectLanguage(code: "ja"), ProjectLanguage(code: "ar"),
            ProjectLanguage(code: "pl", translated: 412, total: 418), ProjectLanguage(code: "tr"), ProjectLanguage(code: "he"),
            ProjectLanguage(code: "iw"), ProjectLanguage(code: "tlh"),
        ],
        languageSource: "Localizable.xcstrings",
        reportedBy: "Claude Code",
        updated: Date(timeIntervalSince1970: 0)
    )

    @Test func missingLanguagesAreTheProjectsNotOnTheStoreEachOnce() {
        let missing = Self.lumen.languagesMissing(from: Self.storeLocales)
        #expect(missing.map(\.code) == ["pl", "tr", "he"])
    }

    @Test func nothingIsMissingWhenTheStoreHasEverything() {
        #expect(Self.lumen.languagesMissing(from: Self.storeLocales + ["pl", "tr", "he"]).isEmpty)
    }

    @Test func devicesAreLookedUpByDisplayType() {
        #expect(Self.lumen.device(.watch)?.reason == "Lumen has a watch app, LumenWatch")
        #expect(Self.lumen.device(.visionPro) == nil)
    }

    @Test func theFoundSummaryNamesTargetsAndLanguages() {
        #expect(Self.lumen.foundSummary(storeLocales: Self.storeLocales)
            == "targets Lumen (iOS, visionOS) and LumenWatch Watch App, and 7 languages in Localizable.xcstrings, 4 of them on the App Store")
        let languagesOnly = AppSupportProfile(languages: [ProjectLanguage(code: "pl")], updated: .now)
        #expect(languagesOnly.foundSummary(storeLocales: []) == "1 language in the project, not on the App Store yet")
        #expect(AppSupportProfile(updated: .now).foundSummary(storeLocales: []).isEmpty)
        let targetsOnly = AppSupportProfile(targets: ["Lumen (iOS)"], updated: .now)
        #expect(targetsOnly.foundSummary(storeLocales: []) == "targets Lumen (iOS)")
    }
}
