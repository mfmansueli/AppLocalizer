//
//  ScreenshotScript.swift
//  AppLocalizer
//

import Foundation

/// The writing system a locale's captions are in. It picks the fallback
/// font (`fonts.fallback.<script>`) and how lines break: between words,
/// by dictionary for Thai, between characters for Chinese, Japanese and
/// Korean.
enum ScreenshotScript: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case latin
    case cyrillic
    case greek
    case vietnamese
    case arabic
    case hebrew
    case japanese = "ja"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case korean = "ko"
    case thai
    case devanagari

    var id: String { rawValue }

    init(locale: StoreLocale) {
        self = Self.byLocale[locale.code] ?? .latin
    }

    /// The App Store locales that aren't written in Latin script.
    private static let byLocale: [String: ScreenshotScript] = [
        "ar-SA": .arabic, "he": .hebrew, "ja": .japanese, "ko": .korean, "zh-Hans": .simplifiedChinese,
        "zh-Hant": .traditionalChinese, "th": .thai, "hi": .devanagari, "ru": .cyrillic, "uk": .cyrillic,
        "el": .greek, "vi": .vietnamese,
    ]

    var title: String {
        switch self {
        case .latin: String(localized: "Latin")
        case .cyrillic: String(localized: "Cyrillic")
        case .greek: String(localized: "Greek")
        case .vietnamese: String(localized: "Vietnamese")
        case .arabic: String(localized: "Arabic")
        case .hebrew: String(localized: "Hebrew")
        case .japanese: String(localized: "Japanese")
        case .simplifiedChinese: String(localized: "Chinese (Simpl.)")
        case .traditionalChinese: String(localized: "Chinese (Trad.)")
        case .korean: String(localized: "Korean")
        case .thai: String(localized: "Thai")
        case .devanagari: String(localized: "Devanagari")
        }
    }

    var isRightToLeft: Bool { self == .arabic || self == .hebrew }

    /// Lines may break between any two characters (with kinsoku).
    var breaksBetweenCharacters: Bool {
        switch self {
        case .japanese, .simplifiedChinese, .traditionalChinese, .korean: true
        default: false
        }
    }

    /// Letters a font must have to count as drawing this script, used to
    /// check a fallback font before a template accepts it.
    var sampleText: String {
        switch self {
        case .latin: "AaZzÉéß"
        case .cyrillic: "АаЯяЖж"
        case .greek: "ΑαΩωΣσ"
        case .vietnamese: "ẠạỞởỮữ"
        case .arabic: "ابتثجح"
        case .hebrew: "אבגדהו"
        case .japanese: "あア日本語"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .korean: "한국어"
        case .thai: "กขคงจฉ"
        case .devanagari: "कखगघङच"
        }
    }
}
