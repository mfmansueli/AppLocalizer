//
//  ProjectLanguageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A string catalog's language as an App Store locale, and how it's
/// described.
@Suite("Project languages")
struct ProjectLanguageTests {
    @Test(arguments: [
        ("pl", "pl"), ("de", "de-DE"), ("tr", "tr"), ("he", "he"), ("iw", "he"),
        ("es", "es-ES"), ("fr", "fr-FR"), ("pt", "pt-PT"), ("pt-BR", "pt-BR"), ("en", "en-US"), ("en-GB", "en-GB"),
        ("zh-Hans", "zh-Hans"), ("zh_TW", "zh-Hant"), ("nb", "no"),
    ])
    func catalogCodesBecomeAppStoreLocales(code: String, expected: String) {
        #expect(ProjectLanguage.storeLocale(for: code)?.code == expected)
    }

    @Test func anUnknownCodeHasNoLocale() {
        #expect(ProjectLanguage(code: "tlh").storeLocale == nil)
        #expect(ProjectLanguage(code: "").storeLocale == nil)
    }

    @Test func coverageShowsThePercentOnlyWhenSomethingIsMissing() {
        #expect(ProjectLanguage(code: "pl", translated: 412, total: 418).coverage == "412 of 418 strings (98%)")
        #expect(ProjectLanguage(code: "tr", translated: 418, total: 418).coverage == "418 of 418 strings")
        #expect(ProjectLanguage(code: "tr", total: 418).coverage == "418 of 418 strings")
        #expect(ProjectLanguage(code: "tr", translated: 3).coverage == nil)
    }

    @Test func evidenceJoinsTheSourceCoverageAndNote() {
        let hebrew = ProjectLanguage(code: "he", translated: 401, total: 418, note: "Right to left; tested in LumenUITests")
        #expect(hebrew.evidence(source: "Localizable.xcstrings") == "Localizable.xcstrings: 401 of 418 strings (95%) · Right to left; tested in LumenUITests")
        #expect(ProjectLanguage(code: "tr").evidence(source: nil) == "")
        #expect(ProjectLanguage(code: "tr", note: "Added in 1.4").evidence(source: "Localizable.xcstrings") == "Localizable.xcstrings · Added in 1.4")
    }
}
