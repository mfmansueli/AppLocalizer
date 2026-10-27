//
//  StoreLocaleCatalogTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("StoreLocaleCatalog")
struct StoreLocaleCatalogTests {
    private let all = StoreLocaleCatalog.all

    @Test func hasThe39AppStoreLocalesOnce() {
        #expect(all.count == 39)
        #expect(Set(all.map(\.code)).count == 39)
        #expect(Set(all.map(\.name)).count == 39)
    }

    @Test func keepsAppStoreConnectsOrderAndCodes() {
        #expect(all.first?.code == "ar-SA")
        #expect(all.last?.code == "vi")
        #expect(all.map(\.code).contains("zh-Hans"))
        #expect(all.map(\.code).contains("no"))
        #expect(StoreLocale.englishUS.name == "English (U.S.)")
        #expect(StoreLocale.portugueseBrazil.name == "Portuguese (Brazil)")
    }

    @Test func onlyArabicAndHebrewAreRightToLeft() {
        #expect(all.filter(\.isRTL).map(\.code) == ["ar-SA", "he"])
    }

    @Test func flagsUseRegionalIndicators() {
        #expect(StoreLocale.german.flag == "🇩🇪")
        #expect(StoreLocale.japanese.flag == "🇯🇵")
        #expect(StoreLocale.arabic.flag == "🇸🇦")
        #expect(StoreLocale.catalan.flag == "🇦🇩")
        #expect(StoreLocale.englishUK.flag == "🇬🇧")
    }

    @Test func translationLanguages() {
        #expect(StoreLocale.german.languageIdentifier == "de")
        #expect(StoreLocale.norwegian.languageIdentifier == "nb")
        #expect(StoreLocale.portugueseBrazil.language.languageCode?.identifier == "pt")
        #expect(StoreLocale.englishUS.isSameLanguage(as: .englishUK))
        #expect(StoreLocale.portuguesePortugal.isSameLanguage(as: .portugueseBrazil))
        #expect(!StoreLocale.chineseSimplified.isSameLanguage(as: .chineseTraditional))
        #expect(!StoreLocale.german.isSameLanguage(as: .french))
    }

    @Test func exactLookupIgnoresCaseAndUnderscores() {
        #expect(StoreLocaleCatalog.locale(code: "de-DE") == .german)
        #expect(StoreLocaleCatalog.locale(code: "DE_de") == .german)
        #expect(StoreLocaleCatalog.locale(code: " zh-hans ") == .chineseSimplified)
        #expect(StoreLocaleCatalog.locale(code: "de") == nil)
    }

    @Test func resolvingIsTolerantOfOtherTools() {
        #expect(StoreLocaleCatalog.resolve("en-us") == .exact(.englishUS))
        #expect(StoreLocaleCatalog.resolve("de") == .inferred(.german))
        #expect(StoreLocaleCatalog.resolve("it-IT") == .inferred(.italian))
        #expect(StoreLocaleCatalog.resolve("ja_JP") == .inferred(.japanese))
        #expect(StoreLocaleCatalog.resolve("nb") == .exact(.norwegian))
        #expect(StoreLocaleCatalog.resolve("zh-TW") == .exact(.chineseTraditional))
        #expect(StoreLocaleCatalog.resolve("es-419") == .exact(.spanishMexico))
        #expect(StoreLocaleCatalog.resolve("pt") == .ambiguous([.portugueseBrazil, .portuguesePortugal]))
        #expect(StoreLocaleCatalog.resolve("zh").locale == nil)
        #expect(StoreLocaleCatalog.resolve("xx") == .unknown)
        #expect(StoreLocaleCatalog.resolve("") == .unknown)
    }

    @Test func siblingPairs() {
        let pairs = StoreLocaleCatalog.siblingPairs.map(\.id)
        #expect(pairs == [
            "en-US→en-GB", "en-US→en-AU", "en-US→en-CA", "es-ES→es-MX", "pt-BR→pt-PT", "pt-PT→pt-BR", "fr-FR→fr-CA",
        ])
        #expect(StoreLocaleCatalog.siblingPairs.first?.title == "English (U.S.) → English (U.K.)")
        #expect(StoreLocaleCatalog.siblingPairs(into: .portugueseBrazil).map(\.source) == [.portuguesePortugal])
        #expect(StoreLocaleCatalog.siblingPairs(into: .german).isEmpty)
    }
}
