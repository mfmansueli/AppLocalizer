//
//  StoreLocale+SimulatorLaunch.swift
//  AppLocalizer
//

import Foundation

extension StoreLocale {
    /// How the simulator launches the app in this locale: its language as
    /// iOS names it (`nb` for App Store Connect's `no`, `de` for `de-DE`)
    /// and the country its App Store page is for, so dates, numbers and
    /// currencies look as they do there: `-AppleLanguages (ja) -AppleLocale
    /// ja_JP`, `-AppleLanguages (zh-Hans) -AppleLocale zh-Hans_CN`.
    var simulatorLaunchArguments: String {
        "-AppleLanguages (\(languageIdentifier)) -AppleLocale \(simulatorLanguage)_\(regionCode)"
    }

    /// The language and script, without a region: `pt` for `pt-BR`,
    /// `zh-Hans` for `zh-Hans`.
    private var simulatorLanguage: String {
        let language = Locale.Language(identifier: languageIdentifier)
        guard let code = language.languageCode?.identifier else { return languageIdentifier }
        guard let script = language.script?.identifier, languageIdentifier.contains(script) else { return code }
        return "\(code)-\(script)"
    }

    /// The launch arguments for an App Store Connect locale code, or the
    /// code itself when the catalog doesn't know it.
    static func simulatorLaunchArguments(for code: String) -> String {
        StoreLocaleCatalog.locale(code: code)?.simulatorLaunchArguments
            ?? "-AppleLanguages (\(code)) -AppleLocale \(code.replacingOccurrences(of: "-", with: "_"))"
    }

    /// The same language and country for UI tests that xcodebuild runs:
    /// `-testLanguage de -testRegion DE`. They reach the app the tests
    /// launch, and nothing goes in front of xcodebuild, which is the only
    /// way AppLocalizer's own Claude Code may run it.
    var xcodebuildTestArguments: String {
        "-testLanguage \(languageIdentifier) -testRegion \(regionCode)"
    }

    /// The test arguments for an App Store Connect locale code; a code the
    /// catalog doesn't know goes as it is, with its region if it has one.
    static func xcodebuildTestArguments(for code: String) -> String {
        if let locale = StoreLocaleCatalog.locale(code: code) { return locale.xcodebuildTestArguments }
        let parts = code.split(separator: "-")
        guard parts.count > 1, let region = parts.last else { return "-testLanguage \(code)" }
        return "-testLanguage \(code) -testRegion \(region)"
    }
}
