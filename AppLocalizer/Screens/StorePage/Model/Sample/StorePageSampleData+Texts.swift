//
//  StorePageSampleData+Texts.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// The prototype’s `TEXTS` and `EN`, verbatim. Every locale shares the three URLs.
extension StorePageSampleData {
    /// Version 1.4’s text in App Store Connect, per locale. Missing fields are left out.
    static let remoteTexts: [StoreLocale: [ListingField: String]] = [
        .englishUS: withURLs(englishUSTexts),
        .englishUK: withURLs(englishUKTexts),
        .german: withURLs(germanTexts),
        .french: withURLs(frenchTexts),
        .spanishSpain: withURLs(spanishSpainTexts),
        .spanishMexico: withURLs(spanishMexicoTexts),
        .portugueseBrazil: withURLs(portugueseBrazilTexts),
        .italian: withURLs(italianTexts),
        .japanese: withURLs(japaneseTexts),
        .arabic: withURLs(arabicTexts),
    ]

    static let urls: [ListingField: String] = [
        .privacyPolicyURL: "https://lumen.example/privacy",
        .supportURL: "https://lumen.example/support",
        .marketingURL: "https://lumen.example",
    ]

    static let englishDescription = """
    Lumen is a quiet place to write every day. Answer a gentle prompt or start from a blank page, add a \
    photo, and Lumen keeps it private on your devices.

    • Daily prompts that adapt to your mood
    • Weekly reflections that gather your highlights
    • Search years of entries in an instant
    • Locked with Face ID, synced with iCloud

    Lumen Plus unlocks unlimited photos, themes and PDF export.
    """

    static let englishWhatsNew = """
    • Weekly reflections: a calm summary of your week
    • Faster search across years of entries
    • Fixes iCloud sync on older devices
    """

    static let spanishDescription = """
    Lumen es un lugar tranquilo para escribir cada día. Responde a una pregunta amable o empieza en \
    blanco, añade una foto y Lumen lo guarda todo en privado en tus dispositivos.

    • Preguntas diarias que se adaptan a tu estado de ánimo
    • Resúmenes semanales con tus mejores momentos
    • Busca años de entradas al instante
    • Protegido con Face ID, sincronizado con iCloud

    Lumen Plus desbloquea fotos ilimitadas, temas y exportación a PDF.
    """

    /// Version 1.3’s What’s New in English (U.S.).
    static let liveWhatsNew = """
    • Live Photos in entries
    • Two new calm themes
    • Bug fixes and performance improvements
    """

    private static func withURLs(_ texts: [ListingField: String]) -> [ListingField: String] {
        texts.merging(urls) { text, _ in text }
    }

    private static let englishUSTexts: [ListingField: String] = [
        .name: "Lumen: Daily Journal",
        .subtitle: "Private notes, gentle prompts",
        .promotionalText: "New: weekly reflections gather your best moments into one calm page.",
        .description: englishDescription,
        .keywords: "diary,mood,gratitude,reflection,writing,mindful,habit,memories,self care,planner,journal",
        .whatsNew: englishWhatsNew,
    ]

    private static let englishUKTexts: [ListingField: String] = [
        .name: "Lumen: Daily Journal",
        .subtitle: "Private notes, gentle prompts",
        .promotionalText: "New: weekly reflections gather your best moments into one calm page.",
        .description: englishDescription,
        .keywords: "diary,mood,gratitude,reflection,writing,mindful,habit,memories,wellbeing,planner",
    ]

    private static let germanTexts: [ListingField: String] = [
        .name: "Lumen: Tagebuch",
        .subtitle: "Private Notizen, sanfte Fragen",
        .promotionalText: "Neu: Wochenrückblicke sammeln deine schönsten Momente auf einer ruhigen Seite.",
        .description: """
        Lumen ist ein ruhiger Ort, um jeden Tag zu schreiben. Beantworte eine sanfte Frage oder beginne mit \
        einer leeren Seite, füge ein Foto hinzu – Lumen bewahrt alles privat auf deinen Geräten.

        • Tägliche Impulse, die sich deiner Stimmung anpassen
        • Wochenrückblicke mit deinen schönsten Momenten
        • Durchsuche Jahre an Einträgen in Sekunden
        • Geschützt mit Face ID, synchronisiert über iCloud

        Lumen Plus schaltet unbegrenzt Fotos, Designs und PDF-Export frei.
        """,
        .keywords: "tagebuch,stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,notizen",
    ]

    private static let frenchTexts: [ListingField: String] = [
        .name: "Lumen : Journal intime",
        .subtitle: "Notes privées, idées douces",
        .promotionalText: "Nouveau : des bilans hebdomadaires réunissent vos plus beaux moments sur une page apaisée.",
        .description: """
        Lumen est un endroit calme pour écrire chaque jour. Répondez à une question douce ou partez d’une \
        page blanche, ajoutez une photo : Lumen garde tout en privé sur vos appareils.

        • Des questions quotidiennes qui s’adaptent à votre humeur
        • Des bilans hebdomadaires qui rassemblent vos meilleurs moments
        • Retrouvez des années de notes en un instant
        • Protégé par Face ID, synchronisé avec iCloud

        Lumen Plus débloque photos illimitées, thèmes et export PDF.
        """,
        .keywords: "journal,humeur,gratitude,réflexion,écriture,habitude,souvenirs,bien-être,notes,pleine conscience",
    ]

    private static let spanishSpainTexts: [ListingField: String] = [
        .name: "Lumen: Diario personal",
        .subtitle: "Notas privadas, ideas amables",
        .promotionalText: "Novedad: los resúmenes semanales reúnen tus mejores momentos en una página tranquila.",
        .description: spanishDescription,
        .keywords: "diario,ánimo,gratitud,reflexión,escritura,hábitos,recuerdos,bienestar,notas,agenda",
    ]

    private static let spanishMexicoTexts: [ListingField: String] = [
        .name: "Lumen: Diario personal",
        .subtitle: "Notas privadas, ideas amables",
        .promotionalText: "Novedad: los resúmenes semanales reúnen tus mejores momentos en una página tranquila.",
        .keywords: "diario,animo,gratitud,reflexion,escritura,habitos,recuerdos,bienestar,notas,agenda",
    ]

    private static let portugueseBrazilTexts: [ListingField: String] = [
        .name: "Lumen: Diário",
        .subtitle: "Diário privado, dicas gentis",
        .promotionalText: "Novo: reflexões semanais reúnem seus melhores momentos em uma página tranquila.",
        .description: """
        O Lumen é um lugar tranquilo para escrever todos os dias. Responda a uma pergunta gentil ou comece \
        do zero, adicione uma foto e deixe tudo guardado só nos seus aparelhos.

        • Perguntas diárias que se adaptam ao seu humor
        • Reflexões semanais com os seus destaques
        • Busque anos de anotações num instante
        • Protegido com Face ID, sincronizado pelo iCloud

        O Lumen Plus libera fotos ilimitadas, temas e exportação em PDF.
        """,
        .keywords: "diario,humor,gratidao,reflexao,escrita,habito,memorias,autocuidado,anotacoes,agenda",
    ]

    private static let italianTexts: [ListingField: String] = [
        .name: "Lumen: Diario",
        .subtitle: "Note private, spunti gentili",
        .description: """
        Lumen è un posto tranquillo per scrivere ogni giorno. Rispondi a una domanda gentile o parti da una \
        pagina bianca, aggiungi una foto: Lumen custodisce tutto in privato sui tuoi dispositivi.

        • Spunti quotidiani che si adattano al tuo umore
        • Riflessioni settimanali con i tuoi momenti migliori
        • Cerca anni di voci in un istante
        • Protetto con Face ID, sincronizzato con iCloud

        Lumen Plus sblocca foto illimitate, temi ed esportazione in PDF.
        """,
        .keywords: "diario,umore,gratitudine,riflessione,scrittura,abitudini,ricordi,benessere,note",
    ]

    private static let japaneseTexts: [ListingField: String] = [
        .name: "Lumen：毎日の日記",
        .subtitle: "プライベートなメモとやさしい問いかけ",
        .promotionalText: "新機能：週ごとの振り返りで、いちばんの瞬間を穏やかな1ページにまとめます。",
        .description: """
        Lumenは、毎日書くための静かな場所です。やさしい問いかけに答えても、白紙から始めても大丈夫。写真を添えれば、すべてはあなたのデバイスの中だけに保存されます。

        • 気分に合わせて変わる毎日の問いかけ
        • 1週間のハイライトをまとめる振り返り
        • 何年分の記録もすぐに検索
        • Face IDでロック、iCloudで同期

        Lumen Plusで写真の無制限追加、テーマ、PDF書き出しが使えます。
        """,
        .keywords: "日記,ジャーナル,気分,感謝,振り返り,習慣,メモ,マインドフル,思い出",
    ]

    private static let arabicTexts: [ListingField: String] = [
        .name: "لومن: يوميات",
        .subtitle: "ملاحظات خاصة وأسئلة لطيفة",
        .promotionalText: "جديد: تأملات أسبوعية تجمع أجمل لحظاتك في صفحة واحدة هادئة.",
        .description: """
        لومن مكان هادئ للكتابة كل يوم. أجب عن سؤال لطيف أو ابدأ بصفحة فارغة، وأضف صورة، ويحتفظ لومن بكل شيء \
        بخصوصية على أجهزتك.

        • أسئلة يومية تتكيّف مع مزاجك
        • تأملات أسبوعية تجمع أبرز لحظاتك
        • ابحث في سنوات من اليوميات في لحظة
        • محمي بـ Face ID ومتزامن عبر iCloud

        يفتح Lumen Plus الصور غير المحدودة والسمات والتصدير بصيغة PDF.
        """,
        .keywords: "يوميات,مذكرات,مزاج,امتنان,تأمل,كتابة,عادات,ذكريات",
    ]
}
#endif
