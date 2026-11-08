//
//  ReviewsLayoutTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// A Reviews slot: no device, three real 5-star App Store reviews under the
/// headline, from the language's own storefront, filled from the primary
/// language's where it has fewer, and checked before push.
@MainActor
@Suite("Reviews slot")
struct ReviewsLayoutTests {
    private let proof = ScreenshotTemplate.starter(.socialProof, id: "lumen", title: "Lumen")

    private static func quotes(_ country: String, _ count: Int) -> [StoreQuote] {
        (0..<count).map { StoreQuote(text: "A review from \(country) number \($0 + 1), long enough to read.", name: "Name\($0 + 1)", country: country) }
    }

    private static var reviews: StoreReviews {
        var reviews = StoreReviews.none
        reviews.primaryCountry = "US"
        reviews.record(quotes("US", 4), inCountry: "US")
        reviews.record(quotes("DE", 1), inCountry: "DE")
        reviews.record([], inCountry: "JP")
        return reviews
    }

    private func layout(_ locale: StoreLocale, reviews: StoreReviews = Self.reviews, slot: Int = 1) -> ScreenshotLayout {
        let engine = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts, reviews: reviews)
        return engine.layout(proof, slot: slot, locale: locale, displayType: .iPhone, caption: ScreenshotCaption(headline: "People love it"))
    }

    @Test func slotTwoQuotesThreeReviewsWithoutADevice() {
        let result = layout(.englishUS)
        #expect(result.device == nil)
        #expect(result.reviews == LayoutReviews(own: 3, borrowed: 0, isChecked: true, signature: result.reviews?.signature ?? ""))
        let names = result.lines.filter { $0.text.hasPrefix("– ") }.map(\.text)
        #expect(names == ["– Name1", "– Name2", "– Name3"])
        let rules = result.decorations.filter { $0.shape == .rule }
        #expect(rules.count == 3, "A drawn rule above each review")
        #expect(rules.allSatisfy { $0.frame.minY > result.captionBox.maxY })
        #expect(result.lines.filter { $0.frame.minY > result.captionBox.maxY }.allSatisfy { $0.alignment == .center })
        #expect(result.lines.allSatisfy { $0.frame.maxY <= result.canvas.height }, "Every review fits on the canvas")
    }

    @Test func fewerThanThreeAreFilledFromThePrimaryLanguage() {
        let german = layout(.german)
        #expect(german.reviews?.own == 1)
        #expect(german.reviews?.borrowed == 2)
        let checks = ScreenshotChecker.checks(for: german, capture: nil, primaryLocaleName: "English (U.S.)")
        let check = checks.first { $0.kind == .reviews }
        #expect(check?.status == .warning)
        #expect(check?.text == "2 of 3 reviews are English (U.S.) reviews: Germany has fewer than three yet")
        #expect(!checks.contains { $0.kind == .capturePresent }, "A Reviews slot needs no capture")
    }

    /// Bruma, not on the App Store yet, had an empty second screenshot in
    /// Social Proof: with no review to quote, the slot shows its capture.
    @Test func noReviewsAnywhereShowsTheCaptureInstead() {
        var none = StoreReviews.none
        none.record([], inCountry: "JP")
        let japanese = layout(.japanese, reviews: none)
        #expect(japanese.reviews?.own == 0)
        #expect(japanese.reviews?.showsCapture == true)
        #expect(japanese.device != nil, "Laid out like the others")
        #expect(japanese.screen.width > 0)
        #expect(!japanese.decorations.contains { $0.shape == .rule }, "No rules for reviews that aren't there")
        let checks = ScreenshotChecker.checks(for: japanese, capture: nil, primaryLocaleName: "English (U.S.)")
        let check = checks.first { $0.kind == .reviews }
        #expect(check?.status == .warning)
        #expect(check?.blocksPush == false)
        #expect(check?.text == "No 5-star App Store reviews in Japan yet, so this slot shows its capture instead of reviews")
        #expect(checks.contains { $0.kind == .capturePresent }, "Its capture is checked like any other")
        let unread = layout(.japanese, reviews: .none)
        #expect(unread.device != nil, "Not looked up yet: the capture too")
        let unreadCheck = ScreenshotChecker.checks(for: unread, capture: nil, primaryLocaleName: "English").first { $0.kind == .reviews }
        #expect(unreadCheck?.status == .warning, "Not looked up yet only warns")
    }

    /// Bruma's Review kept showing the empty slot cached before the capture
    /// took its place: same key, so the cache gave the old render back.
    @Test func theCaptureInPlaceOfReviewsRendersUnderItsOwnKey() {
        var none = StoreReviews.none
        none.record([], inCountry: "JP")
        let capture = layout(.japanese, reviews: none)
        var empty = capture
        empty.reviews?.showsCapture = false
        #expect(capture.storeSignature != nil)
        #expect(capture.storeSignature != empty.storeSignature, "Not the empty slot's key")
        var quoted = layout(.englishUS)
        let signature = quoted.storeSignature
        quoted.reviews?.showsCapture = false
        #expect(quoted.storeSignature == signature, "Quoted reviews keep the key they had")
    }

    @Test func reviewsThatArriveTakeTheCapturesPlace() {
        var none = StoreReviews.none
        none.record([], inCountry: "US")
        let before = layout(.englishUS, reviews: none)
        let after = layout(.englishUS)
        #expect(before.device != nil)
        #expect(after.device == nil)
        #expect(before.storeSignature != after.storeSignature, "Renders again once reviews arrive")
    }

    @Test func rightToLeftNamesEndWithTheDash() {
        var arabic = StoreReviews.none
        arabic.record([StoreQuote(text: "هادئ وخاص وجميل. أشعر أنه لي وحدي تمامًا.", name: "خالد", country: "SA")], inCountry: "SA")
        let result = layout(.arabic, reviews: arabic)
        #expect(result.lines.contains { $0.text == "خالد –" })
    }

    @Test func newReviewsRenderAgain() {
        let before = layout(.englishUS)
        var more = Self.reviews
        more.record(Self.quotes("US", 3).reversed(), inCountry: "US")
        let after = layout(.englishUS, reviews: more)
        #expect(before.storeSignature != nil)
        #expect(before.storeSignature != after.storeSignature, "The render key follows the reviews")
        let device = layout(.englishUS, slot: 3)
        #expect(device.storeSignature == nil, "A slot without App Store content keeps its key")
    }

    @Test func picksReadableReviewsOnce() {
        let picked = StoreReviews.pick([
            StoreQuote(text: "Great", name: "A", country: "US"),
            StoreQuote(text: "I write every night now and it feels calm.", name: "B", country: "US"),
            StoreQuote(text: "I write every night now and it feels calm.", name: "C", country: "US"),
            StoreQuote(text: String(repeating: "Long ", count: 60), name: "D", country: "US"),
            StoreQuote(text: "No name on this one, though it reads well.", name: "", country: "US"),
        ])
        #expect(picked.map(\.name) == ["B"])
    }

    @Test func theSocialProofStarterHasAReviewsSlot() {
        #expect(proof.isQuotes(slot: 1))
        #expect(proof.showsReviews)
        #expect(!ScreenshotTemplate.starter(.socialProof, id: "x", title: "X", slotCount: 8).isQuotes(slot: 5), "Repeated slots get a phone")
    }
}
