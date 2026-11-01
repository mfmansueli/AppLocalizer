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
}
