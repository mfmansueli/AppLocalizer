//
//  DebugStoreProof.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// What the App Store says about Lumen in DEBUG scenes, as on the design
/// canvas: its rating per country (none yet in South Korea and Israel)
/// and a few 5-star reviews in English, German, Japanese and Arabic.
enum DebugStoreProof {
    /// Average and count by country.
    static let ratings: [String: (average: Double?, count: Int)] = [
        "US": (4.8, 220), "GB": (4.8, 41), "DE": (4.7, 64), "FR": (4.6, 38), "ES": (4.7, 22), "IT": (4.8, 17),
        "BR": (4.9, 26), "JP": (4.9, 31), "NL": (4.8, 11), "SA": (4.8, 12), "KR": (nil, 0), "IL": (nil, 0),
    ]

    static let reviews: [String: [(text: String, name: String)]] = [
        "US": [
            ("I’ve written more this year than in the last five. The prompts make it easy.", "Maya"),
            ("Calm, private and beautiful. It feels like it’s mine.", "Daniel"),
            ("Searching old entries is magic. I found a day from 2019 in seconds.", "Priya"),
        ],
        "DE": [
            ("Ich habe dieses Jahr mehr geschrieben als in den letzten fünf. Die Fragen machen es leicht.", "Lena"),
            ("Ruhig, privat und schön. Es fühlt sich wie meins an.", "Jonas"),
            ("Die Suche ist Magie. Einen Tag aus 2019 in Sekunden gefunden.", "Sophie"),
        ],
        "JP": [
            ("今年は過去5年より多く書けました。問いかけのおかげです。", "さくら"),
            ("静かで、プライベートで、美しい。自分だけの場所です。", "けんた"),
            ("検索が魔法みたい。2019年の日も数秒で見つかりました。", "ゆい"),
        ],
        "SA": [
            ("كتبتُ هذا العام أكثر من السنوات الخمس الماضية. الأسئلة تجعل الأمر سهلًا.", "مريم"),
            ("هادئ وخاص وجميل. أشعر أنه لي وحدي.", "خالد"),
            ("البحث في اليوميات القديمة سحر. وجدت يومًا من 2019 في ثوانٍ.", "سارة"),
        ],
    ]

    static func storeRatings(countries: Set<String>) -> StoreRatings {
        var result = StoreRatings.unchecked
        for country in countries {
            let entry = ratings[country.uppercased()] ?? (4.8, 9)
            result.record(entry.average.map { .rated($0) } ?? .unrated, count: entry.average == nil ? nil : entry.count, inCountry: country)
        }
        return result
    }

    static func storeReviews(countries: Set<String>, primaryCountry: String = "US") -> StoreReviews {
        var result = StoreReviews.none
        result.primaryCountry = primaryCountry
        for country in countries {
            let quotes = (reviews[country.uppercased()] ?? []).map { StoreQuote(text: $0.text, name: $0.name, country: country.uppercased()) }
            result.record(quotes, inCountry: country)
        }
        return result
    }
}
#endif
