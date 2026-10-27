//
//  StoreLocaleCatalog+Resolve.swift
//  AppLocalizer
//

import Foundation

extension StoreLocaleCatalog {
    /// Matches a locale code from an imported file or another tool, which
    /// rarely uses App Store Connect's exact codes: case and `_` don't
    /// matter, common aliases are known (`nb` → `no`, `zh-TW` → `zh-Hant`),
    /// and a bare or unknown-region language (`de`, `it-IT`) picks the only
    /// App Store locale for it. `pt` or `en` are ambiguous.
    static func resolve(_ rawCode: String) -> StoreLocaleMatch {
        let code = normalized(rawCode)
        guard !code.isEmpty else { return .unknown }
        if let locale = byCode[code] { return .exact(locale) }
        if let alias = aliases[code], let locale = byCode[alias] { return .exact(locale) }
        let languageCode = String(code.prefix { $0 != "-" })
        let candidates = all.filter { $0.languageCode.lowercased() == languageCode }
        switch candidates.count {
        case 0: return .unknown
        case 1: return .inferred(candidates[0])
        default: return .ambiguous(candidates)
        }
    }

    /// Codes other tools use for an App Store locale, normalized.
    private static let aliases: [String: String] = [
        "nb": "no", "nb-no": "no", "no-no": "no",
        "zh-cn": "zh-hans", "zh-sg": "zh-hans", "zh-hans-cn": "zh-hans",
        "zh-tw": "zh-hant", "zh-hk": "zh-hant", "zh-mo": "zh-hant", "zh-hant-tw": "zh-hant", "zh-hant-hk": "zh-hant",
        "iw": "he", "in": "id",
        "es-419": "es-mx", "es-us": "es-mx",
    ]
}
