//
//  StoreLocaleCatalog.swift
//  AppLocalizer
//

import Foundation

/// Every App Store locale, in App Store Connect's order (alphabetical by
/// English name), plus lookup by code and the sibling pairs Fill offers.
enum StoreLocaleCatalog {
    static let all: [StoreLocale] = [
        .arabic, .catalan, .chineseSimplified, .chineseTraditional, .croatian, .czech, .danish, .dutch,
        .englishAustralia, .englishCanada, .englishUK, .englishUS, .finnish, .french, .frenchCanada, .german,
        .greek, .hebrew, .hindi, .hungarian, .indonesian, .italian, .japanese, .korean, .malay, .norwegian,
        .polish, .portugueseBrazil, .portuguesePortugal, .romanian, .russian, .slovak, .spanishMexico,
        .spanishSpain, .swedish, .thai, .turkish, .ukrainian, .vietnamese,
    ]

    /// "Copy from a sibling locale": the source's text is a sensible
    /// starting point for the target because they share a language.
    static let siblingPairs: [LocaleSiblingPair] = [
        LocaleSiblingPair(source: .englishUS, target: .englishUK),
        LocaleSiblingPair(source: .englishUS, target: .englishAustralia),
        LocaleSiblingPair(source: .englishUS, target: .englishCanada),
        LocaleSiblingPair(source: .spanishSpain, target: .spanishMexico),
        LocaleSiblingPair(source: .portugueseBrazil, target: .portuguesePortugal),
        LocaleSiblingPair(source: .portuguesePortugal, target: .portugueseBrazil),
        LocaleSiblingPair(source: .french, target: .frenchCanada),
    ]

    /// The locale with exactly this code, ignoring case and accepting `_`
    /// for `-` (`de_de` → `de-DE`). Use `resolve(_:)` for codes from files.
    static func locale(code: String) -> StoreLocale? {
        byCode[normalized(code)]
    }

    /// The sibling pairs that copy into `locale`.
    static func siblingPairs(into locale: StoreLocale) -> [LocaleSiblingPair] {
        siblingPairs.filter { $0.target == locale }
    }

    static let byCode: [String: StoreLocale] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.code.lowercased(), $0) }
    )

    static func normalized(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
    }
}
