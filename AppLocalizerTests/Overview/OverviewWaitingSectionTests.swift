//
//  OverviewWaitingSectionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The Overview's "suggestions waiting for you": one row per section, in the
/// design's order, saying where the suggestions are or that it's reviewed.
@Suite("Overview waiting rows")
struct OverviewWaitingSectionTests {
    @Test func eachSectionSaysWhereItsSuggestionsAre() {
        let facts = OverviewWaitingSection.Facts(
            counts: SectionBadgeCounts([.storePage: 32, .screenshots: 3, .subscriptionPricing: 2, .appInformation: 4]),
            storePageLanguages: 6, newPages: 2, captionLanguages: 1, informationPages: ["Age Rating", "Accessibility"]
        )
        let rows = OverviewWaitingSection.rows(facts)
        #expect(rows.map(\.section) == [.storePage, .screenshots, .subscriptionPricing, .appInformation])
        #expect(rows.map(\.detail) == [
            "Text in 6 languages, including 2 new pages",
            "Captions in 1 language",
            "Prices for 2 products",
            "Age Rating, Accessibility",
        ])
        #expect(rows.map(\.count) == [32, 3, 2, 4])
        #expect(rows[0].buttonTitle == "Review")
        #expect(rows[0].accessibilityText == "Open Store Page, 32 suggestions to review")
    }

    @Test func aSectionWithNothingWaitingIsReviewed() {
        let rows = OverviewWaitingSection.rows(OverviewWaitingSection.Facts(counts: SectionBadgeCounts()))
        #expect(rows.map(\.detail) == ["Every language reviewed", "Every caption reviewed", "Every price reviewed", "Every page reviewed"])
        #expect(rows.allSatisfy { $0.buttonTitle == "Open" })
        #expect(rows[2].accessibilityText == "Open Pricing")
    }

    @Test func singularsAndAPricingEstimate() {
        let facts = OverviewWaitingSection.Facts(
            counts: SectionBadgeCounts([.storePage: 1, .subscriptionPricing: 1]),
            storePageLanguages: 1, newPages: 1, isPricingEstimate: true
        )
        let rows = OverviewWaitingSection.rows(facts)
        #expect(rows[0].detail == "Text in 1 language, including 1 new page")
        #expect(rows[0].accessibilityText == "Open Store Page, 1 suggestion to review")
        #expect(rows[2].detail == "Prices that likely hold people back")
    }

    @Test func whatEachSectionChanges() {
        let rows = OverviewWaitingSection.rows(OverviewWaitingSection.Facts(counts: SectionBadgeCounts()))
        #expect(rows[0].what(appName: "Lumen") == "The words on the page and in search")
        #expect(rows[2].what(appName: "Lumen") == "What Lumen costs in each country")
        #expect(rows.map(\.systemImage) == ["doc.text", "iphone", "tag", "info.circle"])
    }
}
