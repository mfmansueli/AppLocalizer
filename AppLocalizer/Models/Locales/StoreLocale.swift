//
//  StoreLocale.swift
//  AppLocalizer
//

import Foundation

/// One of the 39 locales an App Store listing can be written in, keyed by
/// the code App Store Connect's API uses (`en-US`, `de-DE`, `ja`,
/// `zh-Hans`). The full list is `StoreLocaleCatalog.all`; each one is also a
/// static member (`.german`, `.englishUS`). Equality and hashing go by
/// `code` alone.
struct StoreLocale: Identifiable, Hashable, Sendable {
    /// App Store Connect's locale code, e.g. `pt-BR` or `no`.
    let code: String
    /// The English name App Store Connect shows, e.g. "Portuguese (Brazil)".
    let name: String
    /// The ISO 3166 region whose flag stands for the locale. Languages
    /// without a region in their code get their main country (`ja` → JP);
    /// see `StoreLocale+Catalog.swift` for the less obvious picks.
    let regionCode: String
    /// Arabic and Hebrew are written right to left. URLs stay left to right.
    let isRTL: Bool
    /// BCP 47 identifier for Apple's Translation framework, e.g. `de` or
    /// `pt-BR`. Region is kept only where the variant differs.
    let languageIdentifier: String

    init(_ code: String, _ name: String, region: String, language: String, isRTL: Bool = false) {
        self.code = code
        self.name = name
        regionCode = region
        languageIdentifier = language
        self.isRTL = isRTL
    }

    var id: String { code }

    /// The language part of the code: `de` for `de-DE`, `zh` for `zh-Hans`.
    var languageCode: String {
        String(code.prefix { $0 != "-" })
    }

    /// The language to hand to the Translation framework.
    var language: Locale.Language {
        Locale.Language(identifier: languageIdentifier)
    }

    /// The regional-indicator flag glyph, e.g. 🇩🇪 for `de-DE`.
    var flag: String {
        let base: UInt32 = 0x1F1E6 - 0x41
        var flag = ""
        for scalar in regionCode.uppercased().unicodeScalars {
            guard let indicator = Unicode.Scalar(base + scalar.value) else { continue }
            flag.unicodeScalars.append(indicator)
        }
        return flag
    }

    static func == (lhs: StoreLocale, rhs: StoreLocale) -> Bool {
        lhs.code == rhs.code
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
