//
//  StoreGetTitleTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The Get button in the preview's header, in the preview's language.
@Suite("StoreGetTitle")
struct StoreGetTitleTests {
    @Test(arguments: [
        ("ar-SA", "احصل"),
        ("de-DE", "Laden"),
        ("ja", "入手"),
        ("fr-CA", "Obtenir"),
        ("pt-BR", "Obter"),
        ("nl-NL", "Download"),
        ("en-GB", "Get"),
    ])
    func theButtonSpeaksTheLanguage(locale: String, title: String) {
        #expect(StoreGetTitle.title(for: locale) == title)
    }

    @Test(arguments: [
        ("zh-Hans", "获取"),
        ("zh-Hant", "取得"),
        ("zh-TW", "取得"),
        ("zh-HK", "取得"),
        ("zh-CN", "获取"),
    ])
    func chineseFollowsItsScript(locale: String, title: String) {
        #expect(StoreGetTitle.title(for: locale) == title)
    }

    @Test(arguments: ["xx-YY", "", "-"])
    func anUnknownLanguageFallsBackToEnglish(locale: String) {
        #expect(StoreGetTitle.title(for: locale) == "Get")
    }
}
