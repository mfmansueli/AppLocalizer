//
//  StoreGetTitle.swift
//  AppLocalizer
//

import Foundation

/// The App Store's Get button in each language, for the preview's header.
enum StoreGetTitle {
    private static let titles: [String: String] = [
        "ar": "احصل", "ca": "Obtén", "cs": "Získat", "da": "Hent", "de": "Laden", "el": "Λήψη", "en": "Get",
        "es": "Obtener", "fi": "Lataa", "fr": "Obtenir", "he": "קבל", "hi": "प्राप्त करें", "hr": "Preuzmi",
        "hu": "Letöltés", "id": "Dapatkan", "it": "Ottieni", "ja": "入手", "ko": "받기", "ms": "Dapatkan",
        "nb": "Hent", "nl": "Download", "no": "Hent", "pl": "Pobierz", "pt": "Obter", "ro": "Obține",
        "ru": "Загрузить", "sk": "Získať", "sv": "Hämta", "th": "รับ", "tr": "Al", "uk": "Завантажити",
        "vi": "Nhận", "zh-Hans": "获取", "zh-Hant": "取得",
    ]

    /// "Laden" for `de-DE`; English for a language it doesn't know.
    static func title(for localeCode: String) -> String {
        let parts = localeCode.split(separator: "-").map(String.init)
        guard let language = parts.first else { return "Get" }
        if language == "zh" {
            let script = parts.contains("Hant") || parts.contains("TW") || parts.contains("HK") ? "zh-Hant" : "zh-Hans"
            return titles[script] ?? "Get"
        }
        return titles[language] ?? "Get"
    }
}
