//
//  SettingsOptionsTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@MainActor
@Suite("Settings options")
struct SettingsOptionsTests {
    @Test func fallbackChainOffersTheOtherIndicesThenTheRegionMedian() {
        #expect(FallbackChainEditor.optionalSteps(chosen: .worldBank) == [.index(.bigMac), .index(.imf), .regionMedian])
        #expect(FallbackChainEditor.optionalSteps(chosen: .bigMac) == [.index(.worldBank), .index(.imf), .regionMedian])
    }

    @Test func commissionTitlesNameTheProgram() {
        #expect(GeneralSettingsTab.commissionRates == [0.15, 0.30])
        #expect(GeneralSettingsTab.title(forCommission: 0.15) == "15% · Small Business Program")
        #expect(GeneralSettingsTab.title(forCommission: 0.30) == "30% · Standard")
    }

    @Test func roundingTitlesSpellTheChoiceOut() {
        #expect(PricingSettingsTab.title(for: .auto) == "Each currency’s usual ending")
        #expect(PricingSettingsTab.title(for: .ninetyNine) == "Always .99")
    }

    @Test func providersExplainThemselves() {
        #expect(TranslationProvider.allCases.count == 3)
        #expect(TranslationProvider.appleTranslation.summary.contains("private"))
        #expect(AIProviderVendor.anthropic.secretName == "translation.anthropic.apiKey")
    }
}
