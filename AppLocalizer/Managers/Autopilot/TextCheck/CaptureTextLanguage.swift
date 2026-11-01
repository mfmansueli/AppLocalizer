//
//  CaptureTextLanguage.swift
//  AppLocalizer
//

import Foundation

/// Compares the languages Vision, Natural Language and App Store Connect
/// name in their own ways: `de` and `de-DE` are German, `nb` and `no` are
/// Norwegian, and `zh-Hans` and `zh-Hant` are two languages.
enum CaptureTextLanguage {
    static func isSame(_ first: String, _ second: String) -> Bool {
        let left = Locale.Language(identifier: first)
        let right = Locale.Language(identifier: second)
        guard let family = family(left), family == self.family(right) else { return false }
        guard family == "zh" else { return true }
        return script(left) == script(right)
    }

    /// "English", "Chinese, Simplified": the language's name in the Mac's
    /// language.
    static func name(of identifier: String) -> String {
        Locale.current.localizedString(forIdentifier: identifier) ?? identifier
    }

    private static func family(_ language: Locale.Language) -> String? {
        guard let code = language.languageCode?.identifier else { return nil }
        return ["nb", "nn"].contains(code) ? "no" : code
    }

    /// `zh` alone means Simplified.
    private static func script(_ language: Locale.Language) -> String? {
        Locale.Language(identifier: language.maximalIdentifier).script?.identifier
    }
}
