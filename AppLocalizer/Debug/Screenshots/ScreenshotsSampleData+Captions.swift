//
//  ScreenshotsSampleData+Captions.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

extension ScreenshotsSampleData {
    /// The design's captions, `headline|subhead` per slot.
    static let captionTexts: [String: [String]] = [
        "en-US": [
            "Write a little every day|Gentle prompts that fit your mood",
            "See your week on one calm page",
            "Search years of entries in seconds",
            "Keep the photos that matter",
            "Private, and only on your devices",
        ],
        // Slot 3 is a little longer than the design's caption so it overflows
        // with SF Pro's real metrics: "1 line too many at 80 u".
        "de-DE": [
            "Schreib jeden Tag ein bisschen|Sanfte Fragen, passend zu deiner Stimmung",
            "Deine Woche auf einer ruhigen Seite",
            "Durchsuche jahrelange Tagebucheinträge in nur wenigen Sekunden",
            "Bewahre die Fotos, die zählen",
            "Privat und nur auf deinen Geräten",
        ],
        "fr-FR": [
            "Écrivez un peu chaque jour|Des questions douces, selon votre humeur",
            "Votre semaine sur une page apaisée",
            "Retrouvez tout en quelques secondes",
            "Gardez les photos qui comptent",
            "Privé, et seulement sur vos appareils",
        ],
        "es-ES": [
            "Escribe un poco cada día|Preguntas amables según tu estado de ánimo",
            "Tu semana en una página tranquila",
            "Busca años de entradas en segundos",
            "Guarda las fotos que importan",
            "Privado y solo en tus dispositivos",
        ],
        "es-MX": [
            "Escribe un poco cada día|Preguntas amables según tu estado de ánimo",
            "Tu semana en una página tranquila",
            "Busca años de entradas en segundos",
            "Guarda las fotos que importan",
            "Privado, y solo en tus dispositivos",
        ],
        "it": [
            "Scrivi un po’ ogni giorno|Domande gentili, in base al tuo umore",
            "La tua settimana in una pagina serena",
            "Cerca anni di voci in pochi secondi",
            "Conserva le foto che contano",
            "Privato, e solo sui tuoi dispositivi",
        ],
        "pt-BR": [
            "Escreva um pouco todo dia|Perguntas gentis que combinam com seu humor",
            "Sua semana em uma página tranquila",
            "Busque anos de anotações em segundos",
            "Guarde as fotos que importam",
            "Privado, e só nos seus aparelhos",
        ],
        "ja": [
            "毎日、少しずつ書こう|気分に合わせたやさしい問いかけ",
            "1週間を穏やかな1ページに",
            "何年分の記録も数秒で検索",
            "大切な写真を残そう",
            "プライベートに、あなたのデバイスだけに",
        ],
        "ko": [
            "매일 조금씩 써 보세요|기분에 맞춘 다정한 질문",
            "한 주를 차분한 한 페이지에",
            "몇 년 치 기록도 몇 초 만에 검색",
            "소중한 사진을 간직하세요",
            "나만의 기록, 내 기기에만",
        ],
        "zh-Hans": [
            "每天写一点|贴合心情的温柔提问",
            "一页看完你的一周",
            "几秒内搜索多年日记",
            "留住重要的照片",
            "私密，只在你的设备上",
        ],
        "ar-SA": [
            "اكتب قليلًا كل يوم|أسئلة لطيفة تناسب مزاجك",
            "أسبوعك في صفحة واحدة هادئة",
            "ابحث في سنوات من اليوميات في ثوانٍ",
            "احتفظ بالصور التي تهمّك",
            "خاص، وعلى أجهزتك فقط",
        ],
        "nl-NL": [
            "Schrijf elke dag een beetje|Zachte vragen die bij je stemming passen",
            "Je week op één rustige pagina",
            "Doorzoek jaren aan notities in seconden",
            "Bewaar de foto’s die ertoe doen",
            "Privé, en alleen op je apparaten",
        ],
        "th": [
            "เขียนสักนิดทุกวัน|คำถามอ่อนโยนที่เข้ากับอารมณ์ของคุณ",
            "ทั้งสัปดาห์ในหน้าเดียวที่สงบ",
            "ค้นหาบันทึกหลายปีได้ในไม่กี่วินาที",
            "เก็บรูปภาพที่มีความหมาย",
            "เป็นส่วนตัว และอยู่ในอุปกรณ์ของคุณเท่านั้น",
        ],
        "vi": [
            "Viết một chút mỗi ngày|Câu hỏi nhẹ nhàng hợp với tâm trạng",
            "Cả tuần trên một trang tĩnh lặng",
            "Tìm nhật ký nhiều năm chỉ vài giây",
            "Giữ lại những bức ảnh đáng nhớ",
            "Riêng tư, chỉ trên thiết bị của bạn",
        ],
        // Finnish, Polish, Swedish and Turkish: the locales Translate
        // Missing… fills in the `cap-translate` scenes.
        "fi": [
            "Kirjoita vähän joka päivä|Lempeitä kysymyksiä mielialasi mukaan",
            "Viikkosi yhdellä rauhallisella sivulla",
            "Hae vuosien merkinnöistä sekunneissa",
            "Säilytä tärkeät kuvat",
            "Yksityinen, vain laitteillasi",
        ],
        "pl": [
            "Pisz trochę każdego dnia|Łagodne pytania dopasowane do nastroju",
            "Twój tydzień na jednej spokojnej stronie",
            "Przeszukuj lata wpisów w sekundę",
            "Zachowaj zdjęcia, które się liczą",
            "Prywatnie i tylko na Twoich urządzeniach",
        ],
        "sv": [
            "Skriv lite varje dag|Varsamma frågor efter ditt humör",
            "Hela veckan på en lugn sida",
            "Sök i flera års anteckningar på sekunder",
            "Spara bilderna som betyder något",
            "Privat, och bara på dina enheter",
        ],
        "tr": [
            "Her gün biraz yaz|Ruh haline uygun nazik sorular",
            "Haftan tek bir sakin sayfada",
            "Yılların kayıtlarında saniyede ara",
            "Önemli fotoğrafları sakla",
            "Gizli ve yalnızca senin cihazlarında",
        ],
    ]

    /// The shorter headlines "Suggest a Shorter Version" gets, by locale
    /// and slot.
    static let shorterCaptions: [String: [Int: String]] = [
        "de-DE": [1: "Deine Woche auf einen Blick", 2: "Einträge aus Jahren in Sekunden finden", 4: "Privat. Nur auf deinen Geräten."],
    ]

    /// The captions on en-GB's hand-uploaded set.
    static let legacyCaptions = ["Your private journal", "Daily prompts", "Weekly reflections", "Photos in every entry", "Locked with Face ID"]
}
#endif
