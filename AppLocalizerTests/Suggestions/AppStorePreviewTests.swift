//
//  AppStorePreviewTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The App Store page preview beside the Store Page and on the Overview:
/// the store's own words per language, the texts from App Store Connect,
/// and the facts from the summaries.
@Suite("App Store preview")
struct AppStorePreviewTests {
    @Test func theStoreSpeaksTheStorefrontsLanguage() {
        let german = AppStoreWords.words(for: "de-DE")
        #expect(german.whatsNew == "Neue Funktionen")
        #expect(german.inAppPurchases == "In-App-Käufe")
        #expect(german.versionText("1.4") == "Version 1.4")
        #expect(AppStoreWords.words(for: "no").whatsNew == "Nyheter")
        #expect(AppStoreWords.words(for: "zh-Hant").whatsNew == "新功能")
        #expect(AppStoreWords.words(for: "zh-Hans").whatsNew == "新内容")
        // A language it doesn't know reads English.
        #expect(AppStoreWords.words(for: "xx-YY").whatsNew == "What’s New")
    }

    @Test func theDescriptionIsClippedBeforeMore() {
        #expect(AppStorePreviewModel.clipped("Short", to: 10) == "Short")
        #expect(AppStorePreviewModel.clipped("Write a little every day", to: 7) == "Write a…")
    }

    @Test func withoutRatingsItSaysSo() {
        let model = AppStorePreviewModel(locale: .englishUS)
        #expect(model.ratingText == "—")
        #expect(model.ratingCountText == "No Ratings")
    }

    @Test func theOverviewReadsTheTextsAppStoreConnectHas() {
        let content = StorePageContentFixtures.editable
        let model = AppStorePreviewModel(content: content, locale: .german)
        #expect(model.name.value == "Lumen: Tagebuch")
        #expect(model.subtitle.value == "Private Notizen, sanfte Fragen")
        #expect(!model.name.isSuggested)
        #expect(model.versionString == "2.0")
        #expect(model.whatsNew.value.isEmpty)
    }

    @Test func factsComeFromTheSummaries() {
        var model = AppStorePreviewModel(locale: .englishUS)
        var pricing = PricingSummary.empty
        pricing.products = [PricingSummary.Product(
            id: "1", name: "Annual", productID: "lumen.annual", duration: "1 year", basePrice: "$39.99", isInAppPurchase: false
        )]
        model.addFacts(appInformation: AppInformationSummary(ageRating: "4+", category: "Lifestyle", isAppReviewComplete: true), pricing: pricing)
        #expect(model.ageRating == "4+")
        #expect(model.category == "Lifestyle")
        #expect(model.purchases == [AppStorePreviewModel.Purchase(id: "1", name: "Annual", price: "$39.99")])
        model.addFacts(appInformation: nil, pricing: nil)
        #expect(model.ageRating == nil)
        #expect(model.purchases.isEmpty)
    }
}
