//
//  StorePageSampleData+InAppTexts.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

// The prototype’s `IAPT` and `SHOTS`, verbatim.
extension StorePageSampleData {
    static let products: [InAppTextProduct] = [
        InAppTextProduct(id: "lumen.plus.monthly", referenceName: "Monthly", kind: .subscription),
        InAppTextProduct(id: "lumen.plus.annual", referenceName: "Annual", kind: .subscription),
        InAppTextProduct(id: "lumen.lifetime", referenceName: "Lifetime", kind: .inAppPurchase),
    ]

    /// The In-App Texts view: German’s annual description is over the limit (56/45).
    static let inAppTexts = InAppTextMatrix(
        products: products,
        primaryLocale: .englishUS,
        locales: presentLocales,
        remote: inAppRemoteTexts
    )

    /// Screenshots per locale and size. Spanish (Mexico) has none, so its iPhone column uses English (U.S.).
    static let screenshots = ScreenshotCoverage(primaryLocale: .englishUS, counts: [
        .englishUS: [.iPhone: 6, .iPad: 5, .mac: 4],
        .englishUK: [.iPhone: 6, .iPad: 5, .mac: 4],
        .german: [.iPhone: 6, .iPad: 5, .mac: 0],
        .french: [.iPhone: 6, .iPad: 5, .mac: 4],
        .spanishSpain: [.iPhone: 6, .iPad: 0, .mac: 0],
        .spanishMexico: [.iPhone: 0, .iPad: 0, .mac: 0],
        .portugueseBrazil: [.iPhone: 6, .iPad: 5, .mac: 0],
        .italian: [.iPhone: 5, .iPad: 0, .mac: 0],
        .japanese: [.iPhone: 6, .iPad: 5, .mac: 4],
        .arabic: [.iPhone: 4, .iPad: 0, .mac: 0],
    ])

    /// App Store Connect's in-app texts: locale → column ID → text.
    static let inAppRemoteTexts: [StoreLocale: [String: String]] = [
        .englishUS: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus Monthly",
            "lumen.plus.monthly.description": "Unlimited photos, themes and PDF export",
            "lumen.plus.annual.name": "Lumen Plus Annual",
            "lumen.plus.annual.description": "A year of Lumen Plus — save 33%",
            "lumen.lifetime.name": "Lumen Lifetime",
            "lumen.lifetime.description": "Every Lumen Plus feature, forever",
        ],
        .german: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus monatlich",
            "lumen.plus.monthly.description": "Unbegrenzt Fotos, Designs und PDF-Export",
            "lumen.plus.annual.name": "Lumen Plus jährlich",
            "lumen.plus.annual.description": "Ein Jahr Lumen Plus – du sparst 33 % gegenüber monatlich",
            "lumen.lifetime.name": "Lumen auf Lebenszeit",
        ],
        .french: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus mensuel",
            "lumen.plus.monthly.description": "Photos illimitées, thèmes et export PDF",
            "lumen.plus.annual.name": "Lumen Plus annuel",
            "lumen.plus.annual.description": "Un an de Lumen Plus, 33 % d’économie",
            "lumen.lifetime.name": "Lumen à vie",
            "lumen.lifetime.description": "Toutes les fonctions Lumen Plus, pour toujours",
        ],
        .portugueseBrazil: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus Mensal",
            "lumen.plus.monthly.description": "Fotos ilimitadas, temas e exportação PDF",
            "lumen.plus.annual.name": "Lumen Plus Anual",
            "lumen.plus.annual.description": "Um ano de Lumen Plus — economize 33%",
            "lumen.lifetime.name": "Lumen Vitalício",
            "lumen.lifetime.description": "Todos os recursos do Lumen Plus, para sempre",
        ],
        .japanese: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus 月額",
            "lumen.plus.monthly.description": "写真の無制限追加、テーマ、PDF書き出し",
            "lumen.plus.annual.name": "Lumen Plus 年額",
            "lumen.plus.annual.description": "1年間のLumen Plus（月額より33%お得）",
        ],
        .spanishSpain: [
            "group.name": "Lumen Plus",
            "lumen.plus.monthly.name": "Lumen Plus mensual",
            "lumen.plus.monthly.description": "Fotos ilimitadas, temas y exportación PDF",
            "lumen.plus.annual.name": "Lumen Plus anual",
            "lumen.plus.annual.description": "Un año de Lumen Plus: ahorra un 33 %",
            "lumen.lifetime.name": "Lumen para siempre",
            "lumen.lifetime.description": "Todas las funciones de Lumen Plus, para siempre",
        ],
    ]
}
#endif
