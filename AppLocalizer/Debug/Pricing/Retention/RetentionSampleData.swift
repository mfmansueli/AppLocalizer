//
//  RetentionSampleData.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's retention sample data, as the design's Retention board
/// shows it: "Before you go" in 18 languages (as a message, and as the
/// half-price offer's message, whose German runs to 149 characters), two
/// retention offers, and four Asset Library images.
enum RetentionSampleData {
    static let messageID = "6460000001"
    static let versionID = "6460100001"
    static let name = "Before you go"
    static var monthlyID: String { DebugPricingCatalog.lumenMonthlyID }
    static var annualID: String { DebugPricingCatalog.lumenAnnualID }
    /// When the preview says the service ends.
    static let endDate = Date(timeIntervalSince1970: 1_797_206_400) // 2026-12-14 UTC

    /// Claude Code's shorter German for the offer message.
    static let shorterGerman = "Fotos, Impulse und Suche über Jahre: drei Monate 50 % günstiger. Deine Einträge bleiben in jedem Fall deine."

    // MARK: - Words

    // swiftlint:disable line_length

    /// Header and message by locale, as a message only.
    static let message: [String: (String, String)] = [
        "en-US": ("Everything you wrote stays yours", "If you cancel, your entries stay. Photos, daily prompts and search across years end with this period."),
        "de-DE": ("Alles, was du geschrieben hast, bleibt deins", "Wenn du kündigst, bleiben deine Einträge. Fotos, tägliche Impulse und die Suche über Jahre enden mit diesem Zeitraum."),
        "fr-FR": ("Tout ce que vous avez écrit reste à vous", "Si vous résiliez, vos entrées restent. Photos, questions du jour et recherche sur des années s’arrêtent à la fin."),
        "ja": ("書いたことは、すべてあなたのもの", "解約しても日記は残ります。写真、毎日の問いかけ、何年分もの検索はこの期間の終わりに使えなくなります。"),
        "ar-SA": ("كل ما كتبته يبقى لك", "إذا ألغيت الاشتراك تبقى يومياتك. تنتهي الصور والأسئلة اليومية والبحث عبر السنين مع نهاية هذه الفترة."),
        "es-ES": ("Todo lo que escribiste sigue siendo tuyo", "Si cancelas, tus entradas se quedan. Las fotos, las preguntas diarias y la búsqueda de años terminan con este periodo."),
        "it": ("Tutto ciò che hai scritto resta tuo", "Se annulli, le tue voci restano. Foto, spunti quotidiani e ricerca negli anni finiscono con questo periodo."),
        "pt-BR": ("Tudo o que você escreveu continua seu", "Se você cancelar, suas entradas ficam. Fotos, perguntas diárias e busca ao longo dos anos acabam com este período."),
        "nl-NL": ("Alles wat je schreef blijft van jou", "Als je opzegt, blijven je notities. Foto’s, dagelijkse vragen en zoeken door de jaren stoppen na deze periode."),
        "sv": ("Allt du har skrivit förblir ditt", "Om du säger upp finns dina anteckningar kvar. Foton, dagliga frågor och sökning över åren upphör efter perioden."),
        "ko": ("쓴 모든 글은 계속 당신의 것이에요", "구독을 취소해도 일기는 남아요. 사진, 매일의 질문, 몇 년 치 검색은 이번 기간이 끝나면 종료돼요."),
        "zh-Hans": ("你写下的一切都仍然属于你", "取消后，你的日记仍会保留。照片、每日提问和跨年份搜索将在本期结束时停止。"),
        "zh-Hant": ("你寫下的一切都仍然屬於你", "取消後，你的日記仍會保留。照片、每日提問和跨年份搜尋將在本期結束時停止。"),
        "ru": ("Всё, что вы написали, остаётся вашим", "Если вы отмените подписку, записи останутся. Фото, ежедневные вопросы и поиск за годы закончатся с этим периодом."),
        "tr": ("Yazdığın her şey seninle kalır", "İptal edersen girdilerin kalır. Fotoğraflar, günlük sorular ve yıllar boyunca arama bu dönemle sona erer."),
        "pl": ("Wszystko, co napisałeś, zostaje Twoje", "Jeśli anulujesz, Twoje wpisy zostaną. Zdjęcia, codzienne pytania i wyszukiwanie z lat kończą się z tym okresem."),
        "he": ("כל מה שכתבת נשאר שלך", "אם תבטלו, הרשומות שלכם נשארות. תמונות, שאלות יומיות וחיפוש לאורך שנים יסתיימו בסוף התקופה."),
        "hi": ("आपने जो कुछ लिखा, वह आपका ही रहेगा", "रद्द करने पर भी आपकी प्रविष्टियाँ बनी रहेंगी। फ़ोटो, रोज़ के सवाल और सालों की खोज इस अवधि के साथ खत्म होंगे।"),
    ]

    /// Header and message by locale, with the half-price offer. German runs
    /// over 144.
    static let offer: [String: (String, String)] = [
        "en-US": ("Stay for half price", "Keep photos, daily prompts and search across years for 3 months at 50% off. Your entries stay yours either way."),
        "de-DE": ("Bleib zum halben Preis", "Behalte Fotos, tägliche Impulse und die Suche über all deine Jahre: drei Monate lang 50 % günstiger. Deine Einträge bleiben in jedem Fall ganz deine."),
        "fr-FR": ("Restez à moitié prix", "Photos, questions du jour et recherche sur des années : 3 mois à −50 %. Vos entrées restent à vous dans tous les cas."),
        "ja": ("半額で続けませんか", "写真、毎日の問いかけ、何年分もの検索を3か月間50%オフで。日記はどちらの場合もあなたのものです。"),
        "ar-SA": ("ابقَ بنصف السعر", "احتفظ بالصور والأسئلة اليومية والبحث عبر السنين لمدة 3 أشهر بخصم 50٪. تبقى يومياتك لك في كل الأحوال."),
        "es-ES": ("Quédate a mitad de precio", "Conserva las fotos, las preguntas diarias y la búsqueda de años durante 3 meses al 50 %. Tus entradas son tuyas igualmente."),
        "it": ("Resta a metà prezzo", "Mantieni foto, spunti quotidiani e ricerca negli anni per 3 mesi al 50% di sconto. Le tue voci restano tue comunque."),
        "pt-BR": ("Fique pela metade do preço", "Mantenha fotos, perguntas diárias e busca ao longo dos anos por 3 meses com 50% de desconto. Suas entradas são suas."),
        "nl-NL": ("Blijf voor de halve prijs", "Houd foto’s, dagelijkse vragen en zoeken door de jaren 3 maanden met 50% korting. Je notities blijven hoe dan ook van jou."),
        "sv": ("Stanna kvar till halva priset", "Behåll foton, dagliga frågor och sökning över åren i 3 månader för halva priset. Dina anteckningar är dina oavsett."),
        "ko": ("반값으로 계속 이용하세요", "사진, 매일의 질문, 몇 년 치 검색을 3개월 동안 50% 할인으로 계속 쓰세요. 일기는 어느 쪽이든 당신의 것이에요."),
        "zh-Hans": ("半价继续使用", "以五折继续使用照片、每日提问和跨年份搜索 3 个月。无论如何，你的日记都属于你。"),
        "zh-Hant": ("半價繼續使用", "以五折繼續使用照片、每日提問和跨年份搜尋 3 個月。無論如何，你的日記都屬於你。"),
        "ru": ("Оставайтесь за полцены", "Сохраните фото, ежедневные вопросы и поиск за годы на 3 месяца со скидкой 50%. Ваши записи в любом случае остаются вашими."),
        "tr": ("Yarı fiyatına devam et", "Fotoğrafları, günlük soruları ve yıllar boyunca aramayı 3 ay %50 indirimle koru. Girdilerin her durumda senin."),
        "pl": ("Zostań za pół ceny", "Zachowaj zdjęcia, codzienne pytania i wyszukiwanie z lat przez 3 miesiące o 50% taniej. Twoje wpisy i tak zostają Twoje."),
        "he": ("הישארו בחצי מחיר", "שמרו על תמונות, שאלות יומיות וחיפוש לאורך שנים ל-3 חודשים ב-50% הנחה. הרשומות שלכם נשארות שלכם בכל מקרה."),
        "hi": ("आधी कीमत पर जारी रखें", "फ़ोटो, रोज़ के सवाल और सालों की खोज 3 महीने तक 50% छूट पर रखें। आपकी प्रविष्टियाँ हर हाल में आपकी रहेंगी।"),
    ]

    // swiftlint:enable line_length

    /// The words as texts: English written, the others translated.
    static func texts(_ words: [String: (String, String)]) -> [String: RetentionText] {
        words.reduce(into: [:]) { result, entry in
            result[entry.key] = RetentionText(header: entry.value.0, body: entry.value.1, origin: entry.key == "en-US" ? .written : .translated)
        }
    }

    // MARK: - Messages

    /// "Before you go" as App Store Connect has it: approved, as a message
    /// only, for Monthly and Annual, in 18 languages.
    static var liveMessage: RetentionMessage {
        var localizations: [String: RetentionRemoteLocalization] = [:]
        for (index, entry) in message.sorted(by: { $0.key < $1.key }).enumerated() {
            localizations[entry.key] = RetentionRemoteLocalization(
                id: "64602000\(String(format: "%02d", index))", locale: entry.key, header: entry.value.0, body: entry.value.1
            )
        }
        let remote = RetentionRemoteMessage(
            messageID: messageID,
            referenceName: name,
            subscriptionIDs: [monthlyID, annualID],
            versionID: versionID,
            versionState: .approved,
            hasLiveVersion: true,
            localizations: localizations
        )
        var live = RetentionMessage(remote: remote, image: nil, kind: .message)
        live.texts = texts(message)
        return live
    }

    /// "Before you go" before it was ever pushed, with `kind`'s words.
    static func draft(kind: RetentionMessageKind, image: RetentionImage? = nil) -> RetentionMessage {
        RetentionMessage(
            id: "\(RetentionMessage.draftPrefix)1",
            referenceName: name,
            subscriptionIDs: [monthlyID, annualID],
            kind: kind,
            image: image,
            texts: texts(kind == .offer ? offer : message)
        )
    }

    // MARK: - Offers

    static var offers: [RetentionOffer] {
        [
            RetentionOffer(
                id: "6460300001", subscriptionID: monthlyID, referenceName: "Half price for 3 months", offerID: "retention.half.3m",
                mode: .payAsYouGo, duration: .oneMonth, periodCount: 3, usPrice: Decimal(string: "2.49"), paidMonths: 2
            ),
            RetentionOffer(
                id: "6460300002", subscriptionID: annualID, referenceName: "One month free", offerID: "retention.free.1m",
                mode: .free, duration: .oneMonth, periodCount: 1, paidMonths: 6
            ),
        ]
    }

    // MARK: - Images

    static let moonrise = image("moonrise", name: "Moonrise", art: "moon", height: 1000, note: "used in the header")
    static let pages = image("pages", name: "Pages and Moons", art: "pages", height: 1000, note: "brand pattern")
    static let window = image("window", name: "Night Window", art: "window", height: 1200, note: "from the search artwork")
    static let lake = image("lake", name: "Still Lake", art: "lake", height: 1000, note: "from the header scenes")

    static var images: [RetentionImage] { [moonrise, pages, window, lake] }

    private static func image(_ id: String, name: String, art: String, height: Int, note: String) -> RetentionImage {
        RetentionImage(
            assetID: "asset.\(id)", name: name, fileName: "\(id).png", pixelWidth: 3840, pixelHeight: height, note: note,
            thumbnailTemplate: "\(RetentionImage.samplePrefix)\(art)", hasAlpha: false, isPNG: true
        )
    }
}
#endif
