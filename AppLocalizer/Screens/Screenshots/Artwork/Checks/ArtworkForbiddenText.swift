//
//  ArtworkForbiddenText.swift
//  AppLocalizer
//

import Foundation

/// Finds what Apple doesn't allow in the header and search placements in
/// a text: prices and currency symbols, discounts and percentages, website
/// addresses, ©, claims that can't be verified (#1, award-winning, star
/// ratings), Apple's recognitions (Editors’ Choice, App of the Day, Game
/// of the Day, Apple Design Award, in the App Store's main languages) and
/// other platforms or stores. The text is matched with its accents, width
/// and apostrophes folded, case ignored. Words that are also ordinary
/// words ("windows", "steam", "switch", "sale") are left out, so a match
/// is worth stopping for.
enum ArtworkForbiddenText {
    static func matches(in text: String) -> [ArtworkForbiddenMatch] {
        let folded = fold(text)
        guard !folded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        var found: [ArtworkForbiddenMatch] = []
        var keys: Set<String> = []
        func add(_ kind: ArtworkCheckKind, _ snippet: String) {
            let match = ArtworkForbiddenMatch(kind: kind, snippet: snippet.trimmingCharacters(in: .whitespaces))
            if keys.insert(match.key).inserted { found.append(match) }
        }
        for (kind, expressions) in patterns {
            for expression in expressions {
                let range = NSRange(folded.startIndex..., in: folded)
                for result in expression.matches(in: folded, range: range) {
                    if let snippetRange = Range(result.range, in: folded) { add(kind, String(folded[snippetRange])) }
                }
            }
        }
        for link in links(in: folded) where !found.contains(where: { $0.kind == .url && $0.snippet.contains(link) }) {
            add(.url, link)
        }
        return found
    }

    /// Accents, full-width forms and curly apostrophes folded; case kept.
    static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
            .replacingOccurrences(of: "[’‘`´ʼ]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Website addresses Foundation finds: "example.com", "www.x.io".
    private static func links(in text: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range).compactMap { result in
            Range(result.range, in: text).map { String(text[$0]) }
        }
    }

    // MARK: - Patterns

    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    /// Alternatives as one expression; Latin ones whole words only.
    private static func words(_ phrases: [String], wholeWords: Bool = true) -> NSRegularExpression? {
        let escaped = phrases.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        return regex(wholeWords ? "(?<![\\p{L}\\p{N}])(?:\(escaped))(?![\\p{L}\\p{N}])" : "(?:\(escaped))")
    }

    private static let patterns: [(ArtworkCheckKind, [NSRegularExpression])] = [
        (.price, [
            // A currency sign, with its amount when there is one.
            regex("[-−–]?\\s?\\d[\\d.,' ]*\\s?[$€£¥₹₩₽₺₫₪฿₴₦₱₡₲₵₸₼₾¢]|[$€£¥₹₩₽₺₫₪฿₴₦₱₡₲₵₸₼₾¢]\\s?\\d[\\d.,']*|[$€£¥₹₩₽₺₫₪฿₴₦₱₡₲₵₸₼₾¢]"),
            regex(
                "\\d[\\d.,]*\\s?(?:usd|eur|gbp|jpy|cny|rmb|inr|krw|rub|try|brl|mxn|cad|aud|chf|sek|nok|dkk|pln|czk|huf"
                    + "|kr|zl|kc|lei|yen|euros?|dollars?)(?![\\p{L}])"
                    + "|(?<![\\p{L}])(?:usd|eur|gbp|jpy|cny|rmb|inr|krw|brl|mxn|cad|aud|chf|sek|nok|dkk|pln|r\\$)\\s?\\d[\\d.,]*"
            ),
            regex("\\d[\\d.,]*\\s?(?:円|元|원)"),
        ].compactMap(\.self)),
        (.discount, [
            regex("[-−–+]?\\s?\\d+(?:[.,]\\d+)?\\s?%|%\\s?\\d+|%"),
            regex("\\d+\\s?(?:%\\s?)?off(?![\\p{L}])"),
            words([
                "percent", "per cent", "discount", "discounts", "half price", "prozent", "rabatt", "por ciento", "descuento", "pour cent",
                "remise", "reduction", "per cento", "sconto", "por cento", "desconto", "procent", "korting", "rabat", "indirim", "скидка",
                "процент",
            ]),
            words(["割引", "折扣", "할인", "優惠", "优惠"], wholeWords: false),
        ].compactMap(\.self)),
        (.url, [
            regex("https?://\\S+|(?<![\\p{L}\\p{N}])www\\.\\S+"),
            // Bare domains Foundation may not know: "lumen.app".
            regex(
                "(?<![\\p{L}\\p{N}@.])[a-z0-9-]+(?:\\.[a-z0-9-]+)*"
                    + "\\.(?:com|net|org|app|io|co|dev|me|ai|ly|gg|tv|de|fr|es|it|nl|uk|jp|cn|kr|br|ru|eu|info|biz|xyz)"
                    + "(?:/\\S*)?(?![\\p{L}\\p{N}])"
            ),
        ].compactMap(\.self)),
        (.copyright, [
            regex("[©℗]|\\(c\\)\\s?\\d{4}|(?<![\\p{L}])copyright(?![\\p{L}])"),
        ].compactMap(\.self)),
        (.appleRecognition, [
            words([
                "editor's choice", "editors' choice", "editors choice", "editor choice", "app of the day", "game of the day",
                "app of the year", "game of the year", "apple design award", "apple design awards", "featured by apple",
                "app store award", "app store awards", "app des tages", "spiel des tages", "app du jour", "jeu du jour",
                "choix de la redaction", "app del dia", "juego del dia", "seleccion de los editores", "eleccion de los editores",
                "app del giorno", "gioco del giorno", "scelta della redazione", "app do dia", "jogo do dia", "escolha dos editores",
                "app van de dag", "game van de dag", "keuze van de redactie",
            ]),
            words(["今日のapp", "今日のゲーム", "エディターのおすすめ", "エディターズチョイス", "编辑推荐", "編輯推薦", "今日app", "오늘의 앱", "오늘의 게임", "에디터의 선택"], wholeWords: false),
        ].compactMap(\.self)),
        (.unverifiableClaim, [
            regex("#\\s?1(?!\\d)|(?<![\\p{L}])(?:no|nr|n|num)[.°º]?\\s?1(?!\\d)(?![\\p{L}])"),
            words([
                "number one", "best app", "best apps", "best-selling", "best selling", "bestselling", "top-rated", "top rated", "highest rated",
                "highest-rated", "award-winning", "award winning", "award winner", "most popular", "world's best", "world's #1",
                "preisgekront", "galardonada", "galardonado", "premiado", "premiada", "pluripremiato", "primee",
            ]),
            regex("★{2,}|(?<![\\p{N}])[1-5](?:[.,]\\d)?\\s?(?:★|stars?|sterne|estrellas|etoiles|stelle|estrelas)(?![\\p{L}])|5-star|five-star"),
            words(["受賞", "获奖", "獲獎", "수상"], wholeWords: false),
        ].compactMap(\.self)),
        (.otherPlatform, [
            words([
                "android", "google play", "play store", "galaxy store", "amazon appstore", "appgallery", "huawei", "microsoft store",
                "windows phone", "steam deck", "playstation", "xbox", "nintendo", "chromebook", "chrome os", "chromeos", "wear os",
                "harmonyos", "fire tv", "roku", "tizen",
            ]),
        ].compactMap(\.self)),
    ]
}
