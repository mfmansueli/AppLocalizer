//
//  AppStoreWords.swift
//  AppLocalizer
//

import Foundation

/// The App Store's own words in the storefront's language, for the page
/// preview: people see them there whatever language AppLocalizer is in.
/// English for a language it doesn't know.
struct AppStoreWords: Equatable, Sendable {
    var get: String
    var whatsNew: String
    /// "Version %@".
    var version: String
    var more: String
    var inAppPurchases: String
    /// "%@ Ratings".
    var ratings: String
    var noRatings: String
    var yearsOld: String

    func versionText(_ number: String) -> String {
        version.replacingOccurrences(of: "%@", with: number)
    }

    func ratingsText(_ count: Int) -> String {
        ratings.replacingOccurrences(of: "%@", with: count.formatted(.number.notation(.compactName)))
    }

    private static let english = Words("What’s New", "Version %@", "more", "In-App Purchases", "%@ Ratings", "No Ratings", "Years Old")

    private static let table: [String: Words] = [
        "ar": Words("الجديد", "الإصدار %@", "المزيد", "عمليات شراء داخل التطبيق", "%@ تقييم", "لا توجد تقييمات", "سنة"),
        "ca": Words("Novetats", "Versió %@", "més", "Compres integrades", "%@ valoracions", "Sense valoracions", "anys"),
        "cs": Words("Co je nového", "Verze %@", "více", "Nákupy v aplikaci", "%@ hodnocení", "Bez hodnocení", "let"),
        "da": Words("Nyheder", "Version %@", "mere", "Køb i app", "%@ vurderinger", "Ingen vurderinger", "år"),
        "de": Words("Neue Funktionen", "Version %@", "mehr", "In-App-Käufe", "%@ Bewertungen", "Keine Bewertungen", "Jahre"),
        "el": Words("Τι νέο υπάρχει", "Έκδοση %@", "περισσότερα", "Αγορές εντός εφαρμογής", "%@ αξιολογήσεις", "Χωρίς αξιολογήσεις", "ετών"),
        "es": Words("Novedades", "Versión %@", "más", "Compras dentro de la app", "%@ valoraciones", "Sin valoraciones", "años"),
        "fi": Words("Uutta", "Versio %@", "lisää", "Appin sisäiset ostot", "%@ arvosanaa", "Ei arvosanoja", "vuotta"),
        "fr": Words("Nouveautés", "Version %@", "plus", "Achats intégrés", "%@ notes", "Aucune note", "ans"),
        "he": Words("מה חדש", "גרסה %@", "עוד", "רכישות בתוך היישום", "%@ דירוגים", "אין דירוגים", "גיל"),
        "hi": Words("नया क्या है", "संस्करण %@", "और", "ऐप में ख़रीदारी", "%@ रेटिंग", "कोई रेटिंग नहीं", "वर्ष"),
        "hr": Words("Novosti", "Verzija %@", "više", "Kupnje unutar aplikacije", "%@ ocjena", "Nema ocjena", "god."),
        "hu": Words("Újdonságok", "%@ verzió", "több", "Appon belüli vásárlások", "%@ értékelés", "Nincs értékelés", "év"),
        "id": Words("Yang Baru", "Versi %@", "lainnya", "Pembelian In-App", "%@ Penilaian", "Tidak Ada Penilaian", "Tahun"),
        "it": Words("Novità", "Versione %@", "altro", "Acquisti in app", "%@ valutazioni", "Nessuna valutazione", "anni"),
        "ja": Words("新機能", "バージョン %@", "さらに表示", "App内課金あり", "%@件の評価", "評価なし", "歳以上"),
        "ko": Words("새로운 기능", "버전 %@", "더 보기", "앱 내 구입", "%@개의 평가", "평가 없음", "세"),
        "ms": Words("Apa Yang Baharu", "Versi %@", "lagi", "Pembelian Dalam Aplikasi", "%@ Penilaian", "Tiada Penilaian", "Tahun"),
        "nl": Words("Nieuw", "Versie %@", "meer", "In-app aankopen", "%@ beoordelingen", "Geen beoordelingen", "jaar"),
        "no": Words("Nyheter", "Versjon %@", "mer", "Kjøp i appen", "%@ vurderinger", "Ingen vurderinger", "år"),
        "pl": Words("Co nowego", "Wersja %@", "więcej", "Zakupy w aplikacji", "%@ ocen", "Brak ocen", "Wiek"),
        "pt": Words("Novidades", "Versão %@", "mais", "Compras no App", "%@ avaliações", "Sem avaliações", "anos"),
        "ro": Words("Noutăți", "Versiunea %@", "mai mult", "Achiziții în aplicație", "%@ evaluări", "Nicio evaluare", "ani"),
        "ru": Words("Что нового", "Версия %@", "ещё", "Встроенные покупки", "%@ оценок", "Нет оценок", "лет"),
        "sk": Words("Čo je nové", "Verzia %@", "viac", "Nákupy v aplikácii", "%@ hodnotení", "Bez hodnotení", "rokov"),
        "sv": Words("Nyheter", "Version %@", "mer", "Köp i appen", "%@ betyg", "Inga betyg", "år"),
        "th": Words("มีอะไรใหม่", "เวอร์ชั่น %@", "เพิ่มเติม", "การซื้อภายในแอป", "%@ คะแนน", "ไม่มีคะแนน", "ปี"),
        "tr": Words("Yenilikler", "Sürüm %@", "daha fazla", "Uygulama İçi Satın Alma", "%@ Puan", "Puan yok", "Yaş"),
        "uk": Words("Що нового", "Версія %@", "більше", "Покупки в програмі", "%@ оцінок", "Немає оцінок", "років"),
        "vi": Words("Tính năng mới", "Phiên bản %@", "thêm", "Mua hàng trong ứng dụng", "%@ xếp hạng", "Không có xếp hạng", "tuổi"),
        "zh-Hans": Words("新内容", "版本 %@", "更多", "App 内购买项目", "%@ 个评分", "无评分", "岁"),
        "zh-Hant": Words("新功能", "版本 %@", "更多", "App 內購買", "%@ 則評分", "沒有評分", "歲"),
    ]

    /// The words of `localeCode`, e.g. `de-DE`.
    static func words(for localeCode: String) -> AppStoreWords {
        let entry = table[key(for: localeCode)] ?? english
        return AppStoreWords(
            get: StoreGetTitle.title(for: localeCode),
            whatsNew: entry.whatsNew,
            version: entry.version,
            more: entry.more,
            inAppPurchases: entry.inAppPurchases,
            ratings: entry.ratings,
            noRatings: entry.noRatings,
            yearsOld: entry.yearsOld
        )
    }

    private static func key(for localeCode: String) -> String {
        let parts = localeCode.split(separator: "-").map(String.init)
        guard let language = parts.first else { return "en" }
        if language == "zh" {
            return parts.contains("Hant") || parts.contains("TW") || parts.contains("HK") ? "zh-Hant" : "zh-Hans"
        }
        return language == "nb" ? "no" : language
    }

    private struct Words {
        let whatsNew: String
        let version: String
        let more: String
        let inAppPurchases: String
        let ratings: String
        let noRatings: String
        let yearsOld: String

        init(_ whatsNew: String, _ version: String, _ more: String, _ inAppPurchases: String, _ ratings: String, _ noRatings: String, _ yearsOld: String) {
            self.whatsNew = whatsNew
            self.version = version
            self.more = more
            self.inAppPurchases = inAppPurchases
            self.ratings = ratings
            self.noRatings = noRatings
            self.yearsOld = yearsOld
        }
    }
}
