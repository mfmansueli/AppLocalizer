//
//  ArtworkForbiddenTextTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What Apple doesn't allow on the header and search images, found in a
/// line of text.
@Suite("Artwork forbidden text")
struct ArtworkForbiddenTextTests {
    private func kinds(_ text: String) -> [ArtworkCheckKind] {
        ArtworkForbiddenText.matches(in: text).map(\.kind)
    }

    @Test(arguments: ["Only $4.99", "Nur 4,99 €", "Ab 4,99 EUR", "月額500円", "£3 a month", "R$ 9,90", "Just 99¢"])
    func pricesAndCurrencySymbols(text: String) {
        #expect(kinds(text).contains(.price))
    }

    @Test func thePriceIsQuotedAsWritten() throws {
        let match = try #require(ArtworkForbiddenText.matches(in: "Only $4.99 today").first)
        #expect(match == ArtworkForbiddenMatch(kind: .price, snippet: "$4.99"))
    }

    @Test(arguments: ["−50% this week", "Save 30%", "Jetzt 20 % Rabatt", "50 off", "Half price", "３０％オフ", "限时折扣"])
    func discountsAndPercentages(text: String) {
        #expect(kinds(text).contains(.discount))
    }

    @Test func aDiscountIsQuotedWithItsSign() throws {
        let match = try #require(ArtworkForbiddenText.matches(in: "Jetzt −50%").first { $0.kind == .discount })
        #expect(match.snippet == "−50%")
    }

    @Test(arguments: ["Visit lumen.app", "www.lumen.com", "https://lumen.app/start", "lumenjournal.com/download"])
    func websiteAddresses(text: String) {
        #expect(kinds(text).contains(.url))
    }

    @Test(arguments: ["© 2026 Lumen", "(c) 2026 Lumen Inc.", "Copyright Lumen"])
    func copyright(text: String) {
        #expect(kinds(text) == [.copyright])
    }

    @Test(arguments: [
        "Editor’s Choice", "Editors' Choice", "EDITORS’ CHOICE", "App of the Day", "Game of the Day", "Apple Design Award winner",
        "App des Tages", "Choix de la rédaction", "Juego del día", "今日のApp",
    ])
    func applesRecognitions(text: String) {
        #expect(kinds(text).contains(.appleRecognition))
    }

    @Test(arguments: ["The #1 habit app", "Nr. 1 in Deutschland", "Award-winning journaling", "Top-rated planner", "★★★★★", "4.8 stars"])
    func claimsThatCantBeVerified(text: String) {
        #expect(kinds(text).contains(.unverifiableClaim))
    }

    @Test(arguments: ["Also on Android", "Get it on Google Play", "Now in the Play Store", "Sync with your Xbox"])
    func otherPlatformsAndStores(text: String) {
        #expect(kinds(text) == [.otherPlatform])
    }

    @Test(arguments: [
        "Your week, sorted", "Plan your day in seconds", "Open windows, fresh air", "Let off steam", "Switch tasks fast",
        "Note anything, find it later", "Androids dream of sheep", "Dein Tag, klar geplant", "一日をすっきり整理",
    ])
    func ordinaryLinesPass(text: String) {
        #expect(kinds(text).isEmpty)
    }
}
#endif
