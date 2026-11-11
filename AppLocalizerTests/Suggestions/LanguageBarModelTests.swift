//
//  LanguageBarModelTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The language bar over the Store Page and Screenshots: the language in
/// view and its count, the rest elsewhere, the arrows, and the menu rows.
@Suite("Language bar")
struct LanguageBarModelTests {
    private let japanese = StoreLocale.japanese
    private let french = StoreLocale.french

    private func model(current: StoreLocale, acceptsRightAway: Bool = false) -> LanguageBarModel {
        LanguageBarModel(
            entries: [
                LanguageBarEntry(locale: .englishUS, count: 5),
                LanguageBarEntry(locale: .german, count: 0),
                LanguageBarEntry(locale: french, count: 3),
                LanguageBarEntry(locale: japanese, count: 0),
            ],
            current: current,
            acceptsRightAway: acceptsRightAway
        )
    }

    @Test func theLanguageInViewAndTheRest() {
        let bar = model(current: .englishUS)
        #expect(bar.hereText == "5 suggestions here")
        #expect(bar.restText == "3 more in 1 other language")
        #expect(bar.totalCount == 8)
        #expect(bar.acceptHereTitle == "Accept 5 in English")
        #expect(bar.acceptAllTitle == "Accept All Languages")
        #expect(bar.withSuggestions.map(\.locale) == [.englishUS, french])
        #expect(bar.upToDate.map(\.locale) == [.german, japanese])
    }

    @Test func theArrowsSkipLanguagesWithNothingAndWrapAround() {
        #expect(model(current: .englishUS).next == french)
        #expect(model(current: .englishUS).previous == french)
        #expect(model(current: .german).next == french)
        #expect(model(current: .german).previous == .englishUS)
        #expect(model(current: japanese).next == .englishUS)
    }

    @Test func aLanguageWithNothingToReview() {
        let bar = model(current: .german)
        #expect(bar.hereText == "Nothing to review here")
        #expect(bar.restText == "8 more in 2 other languages")
    }

    @Test func everythingReviewed() {
        let bar = LanguageBarModel(entries: [LanguageBarEntry(locale: .englishUS, count: 0)], current: .englishUS)
        #expect(bar.acceptAllTitle == "All Languages Reviewed")
        #expect(bar.restText.isEmpty, "The button says it; the bar doesn't repeat it")
        #expect(bar.acceptAllAccessibilityText == "Every language is reviewed")
        #expect(bar.next == nil)
    }

    @Test func acceptingRightAwayIsSaid() {
        let bar = model(current: .englishUS, acceptsRightAway: true)
        #expect(bar.menuAcceptAllTitle == "Accept All Languages")
        #expect(bar.acceptAllAccessibilityText == "Accept all languages: 8 suggestions in 2 languages, accepts right away")
        #expect(model(current: .englishUS).menuAcceptAllTitle == "Accept All Languages…")
    }

    @Test func aMenuRowReadsItsCountAndANewPage() {
        let entry = LanguageBarEntry(locale: .german, count: 5, comingCount: 2, isNewPage: true)
        #expect(entry.accessibilityText == "German, 5 suggestions to review, 2 coming, not on the App Store yet")
        #expect(LanguageBarEntry(locale: .german, count: 1).accessibilityText == "German, 1 suggestion to review")
    }

    @Test func aShortNameALanguageBeforeItHasBecomesTheRegion() throws {
        let american = try #require(StoreLocaleCatalog.locale(code: "en-US"))
        let australian = try #require(StoreLocaleCatalog.locale(code: "en-AU"))
        let shown = [american, australian, StoreLocale.german]
        #expect(LanguageBarModel.shortName(american, among: shown) == "English")
        #expect(LanguageBarModel.shortName(australian, among: shown) == "Australia")
        #expect(LanguageBarModel.shortName(.german, among: shown) == "German")
        // The first one shown keeps the language's name, whichever it is.
        #expect(LanguageBarModel.shortName(australian, among: [australian, american]) == "English")
        #expect(LanguageBarModel.shortName(american, among: [australian, american]) == "U.S.")
    }

    @Test func aShortNameOnItsOwnStaysShort() throws {
        let american = try #require(StoreLocaleCatalog.locale(code: "en-US"))
        #expect(LanguageBarModel.shortName(american, among: [american, .german]) == "English")
        #expect(LanguageBarModel.shortName(american, among: []) == "English")
    }
}
