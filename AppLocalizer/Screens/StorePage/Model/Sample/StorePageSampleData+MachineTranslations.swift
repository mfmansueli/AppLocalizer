//
//  StorePageSampleData+MachineTranslations.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// The prototype’s `MTX`, verbatim: what the sample translator returns.
extension StorePageSampleData {
    /// Translations of the primary locale’s text, per locale and field.
    static let machineTranslations: [StoreLocale: [ListingField: String]] = [
        .englishUK: englishUKTranslations,
        .german: germanTranslations,
        .french: frenchTranslations,
        .spanishSpain: spanishSpainTranslations,
        .spanishMexico: spanishMexicoTranslations,
        .portugueseBrazil: portugueseBrazilTranslations,
        .italian: italianTranslations,
        .japanese: japaneseTranslations,
        .arabic: arabicTranslations,
        .korean: koreanTranslations,
        .chineseSimplified: chineseSimplifiedTranslations,
        .dutch: dutchTranslations,
    ]

    private static let englishUKTranslations: [ListingField: String] = [
        .whatsNew: englishWhatsNew,
    ]

    private static let germanTranslations: [ListingField: String] = [
        .whatsNew: """
        • Wochenrückblicke: eine ruhige Zusammenfassung deiner Woche
        • Schnellere Suche über Jahre an Einträgen
        • Behebt die iCloud-Synchronisierung auf älteren Geräten
        """,
    ]

    private static let frenchTranslations: [ListingField: String] = [
        .whatsNew: """
        • Bilans hebdomadaires : un résumé apaisé de votre semaine
        • Recherche plus rapide dans des années de notes
        • Corrige la synchronisation iCloud sur les anciens appareils
        """,
    ]

    private static let spanishSpainTranslations: [ListingField: String] = [
        .whatsNew: """
        • Resúmenes semanales: un repaso tranquilo de tu semana
        • Búsqueda más rápida en años de entradas
        • Corrige la sincronización con iCloud en dispositivos antiguos
        """,
    ]

    private static let spanishMexicoTranslations: [ListingField: String] = [
        .description: spanishDescription,
        .whatsNew: """
        • Resúmenes semanales: un repaso tranquilo de tu semana
        • Búsqueda más rápida en años de entradas
        • Corrige la sincronización con iCloud en dispositivos anteriores
        """,
    ]

    private static let portugueseBrazilTranslations: [ListingField: String] = [
        .whatsNew: """
        • Reflexões semanais: um resumo tranquilo da sua semana
        • Busca mais rápida em anos de anotações
        • Corrige a sincronização do iCloud em aparelhos mais antigos
        """,
    ]

    private static let italianTranslations: [ListingField: String] = [
        .promotionalText: "Novità: le riflessioni settimanali raccolgono i tuoi momenti migliori in una pagina serena.",
        .whatsNew: """
        • Riflessioni settimanali: un riepilogo sereno della tua settimana
        • Ricerca più veloce tra anni di voci
        • Corregge la sincronizzazione iCloud sui dispositivi meno recenti
        """,
    ]

    private static let japaneseTranslations: [ListingField: String] = [
        .whatsNew: """
        • 週ごとの振り返り：1週間を穏やかにまとめます
        • 何年分の記録もより速く検索
        • 古いデバイスでのiCloud同期の問題を修正
        """,
    ]

    private static let arabicTranslations: [ListingField: String] = [
        .whatsNew: """
        • تأملات أسبوعية: ملخص هادئ لأسبوعك
        • بحث أسرع في سنوات من اليوميات
        • إصلاح مزامنة iCloud على الأجهزة الأقدم
        """,
    ]

    private static let koreanTranslations: [ListingField: String] = [
        .name: "Lumen: 매일 일기",
        .subtitle: "나만의 기록, 다정한 질문",
        .promotionalText: "새로운 기능: 주간 회고가 가장 좋았던 순간을 차분한 한 페이지에 모아 드립니다.",
        .description: """
        Lumen은 매일 글을 쓰기 위한 조용한 공간입니다. 다정한 질문에 답하거나 빈 페이지에서 시작하고, 사진을 더해 보세요. 모든 기록은 내 기기에만 안전하게 보관됩니다.

        • 기분에 맞춰 바뀌는 매일의 질문
        • 한 주의 하이라이트를 모은 주간 회고
        • 몇 년 치 기록도 바로 검색
        • Face ID 잠금, iCloud 동기화

        Lumen Plus로 사진 무제한, 테마, PDF 내보내기를 이용하세요.
        """,
        .keywords: "일기,다이어리,감정,감사,회고,습관,메모,마음챙김,기록",
        .whatsNew: """
        • 주간 회고: 한 주를 차분하게 정리해 드립니다
        • 몇 년 치 기록을 더 빠르게 검색
        • 이전 기기의 iCloud 동기화 문제 수정
        """,
    ]

    private static let chineseSimplifiedTranslations: [ListingField: String] = [
        .name: "Lumen：每日日记",
        .subtitle: "私密笔记，温柔提问",
        .promotionalText: "新功能：每周回顾将你最美好的时刻汇集在宁静的一页上。",
        .description: """
        Lumen 是一个每天安静书写的地方。回答一个温柔的问题，或从空白页开始，添加一张照片，所有内容都只保存在你的设备上。

        • 随心情变化的每日提问
        • 汇集一周亮点的每周回顾
        • 瞬间搜索多年的日记
        • 使用面容 ID 锁定，通过 iCloud 同步

        Lumen Plus 解锁无限照片、主题和 PDF 导出。
        """,
        .keywords: "日记,日志,心情,感恩,回顾,习惯,笔记,正念,记录",
        .whatsNew: """
        • 每周回顾：为你安静地总结这一周
        • 更快地搜索多年的日记
        • 修复旧设备上的 iCloud 同步问题
        """,
    ]

    private static let dutchTranslations: [ListingField: String] = [
        .name: "Lumen: Dagboek",
        .subtitle: "Privénotities, zachte vragen",
        .promotionalText: "Nieuw: weekoverzichten bundelen je mooiste momenten op één rustige pagina.",
        .description: """
        Lumen is een rustige plek om elke dag te schrijven. Beantwoord een vriendelijke vraag of begin met \
        een lege pagina, voeg een foto toe en Lumen bewaart alles privé op je apparaten.

        • Dagelijkse vragen die zich aanpassen aan je stemming
        • Weekoverzichten met je hoogtepunten
        • Doorzoek jaren aan notities in een oogwenk
        • Beveiligd met Face ID, gesynchroniseerd via iCloud

        Lumen Plus ontgrendelt onbeperkt foto’s, thema’s en pdf-export.
        """,
        .keywords: "dagboek,stemming,dankbaarheid,reflectie,schrijven,gewoontes,herinneringen,mindfulness,notities",
        .whatsNew: """
        • Weekoverzichten: een rustige samenvatting van je week
        • Sneller zoeken door jaren aan notities
        • Herstelt iCloud-synchronisatie op oudere apparaten
        """,
    ]
}
#endif
