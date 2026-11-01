//
//  CaptureTextLanguageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Vision, Natural Language and App Store Connect name languages their own
/// ways; these are the same language, or not.
@Suite("Capture text language")
struct CaptureTextLanguageTests {
    @Test(arguments: [
        ("de", "de-DE", true), ("en", "en-GB", true), ("pt", "pt-BR", true), ("nb", "no", true), ("nb-NO", "nb", true),
        ("zh", "zh-Hans", true), ("zh-Hans", "zh-Hant", false), ("zh-TW", "zh-Hant", true), ("en", "de", false), ("ja", "ko", false),
    ])
    func languagesCompareByLanguageAndChinesesScript(first: String, second: String, isSame: Bool) {
        #expect(CaptureTextLanguage.isSame(first, second) == isSame)
    }
}
