//
//  ListingFieldValidatorTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("ListingFieldValidator")
struct ListingFieldValidatorTests {
    // MARK: - Counting

    @Test func charactersAreGraphemesAndKeywordsAreUTF8Bytes() {
        #expect(ListingTextMeasure.characters(in: "é") == 1)
        #expect(ListingTextMeasure.utf8Bytes(in: "e") == 1)
        #expect(ListingTextMeasure.utf8Bytes(in: "é") == 2)
        #expect(ListingTextMeasure.characters(in: "日記") == 2)
        #expect(ListingTextMeasure.utf8Bytes(in: "日記") == 6)
        #expect(ListingTextMeasure.characters(in: "يوميات") == 6)
        #expect(ListingTextMeasure.utf8Bytes(in: "يوميات") == 12)
        #expect(ListingTextMeasure.characters(in: "👍🏽") == 1)
        #expect(ListingTextMeasure.utf8Bytes(in: "👍🏽") == 8)
    }

    @Test func sampleKeywordsCostWhatTheGridShows() {
        let texts = StorePageSampleData.remoteTexts
        #expect(ListingTextMeasure.utf8Bytes(in: texts[.englishUS]?[.keywords] ?? "") == 88)
        #expect(ListingTextMeasure.utf8Bytes(in: texts[.spanishSpain]?[.keywords] ?? "") == 85)
        #expect(ListingTextMeasure.utf8Bytes(in: texts[.japanese]?[.keywords] ?? "") == 92)
        #expect(ListingTextMeasure.utf8Bytes(in: texts[.arabic]?[.keywords] ?? "") == 91)
    }

    // MARK: - Limits

    @Test func overTheCharacterLimit() {
        let validation = ListingFieldValidator.validate("Private Notizen, sanfte Impulse", for: .subtitle)
        #expect(validation == .overLimit(count: 31, limit: ListingTextLimit(30)))
        #expect(validation.isBlocking)
        #expect(validation.message == "1 character over the limit.")
        #expect(validation.accessibilityLabel == "Over the limit, 31 of 30 characters")
        let arabic = ListingFieldValidator.validate("ملاحظات خاصة وأسئلة لطيفة كل يوم", for: .subtitle)
        #expect(arabic.message == "2 characters over the limit.")
    }

    @Test func overTheByteLimit() {
        let keywords = "tagebuch, stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,rückblick,notizen,stimmung"
        let validation = ListingFieldValidator.validate(keywords, for: .keywords)
        #expect(validation == .overLimit(count: 114, limit: ListingTextLimit(100, unit: .bytes)))
        #expect(validation.message == "14 bytes over. Each accented letter or CJK character counts as 2–3 bytes.")
        #expect(validation.accessibilityLabel == "Over the limit, 114 of 100 bytes")
    }

    @Test func atTheLimitIsFine() {
        #expect(ListingFieldValidator.validate(String(repeating: "a", count: 30), for: .name) == .valid)
        #expect(ListingFieldValidator.validate(String(repeating: "é", count: 50), for: .keywords) == .valid)
        #expect(ListingFieldValidator.validate(String(repeating: "é", count: 51), for: .keywords).isBlocking)
    }

    @Test(arguments: ["", "  ", "\n"])
    func blankIsEmptyAndDoesntBlock(value: String) {
        #expect(ListingFieldValidator.validate(value, for: .description) == .empty)
        #expect(ListingFieldValidator.validate(value, for: .supportURL) == .empty)
        #expect(!ListingFieldValidation.empty.isBlocking)
    }

    // MARK: - URLs

    @Test(arguments: [
        "https://lumen.example/privacy",
        "https://lumen.example",
        "HTTPS://Lumen.Example/a?b=c#top",
        " https://lumen.example/support\n",
        "https://www.lumen.example:8443/path",
    ])
    func fullHTTPSAddressesAreValid(url: String) {
        #expect(ListingFieldValidator.isValidURL(url))
        #expect(ListingFieldValidator.validate(url, for: .supportURL) == .valid)
    }

    @Test(arguments: [
        "lumen.example/ar/support",
        "http://lumen.example",
        "ftp://lumen.example",
        "https://",
        "https://localhost",
        "https:lumen.example",
        "https://lumen .example",
        "https://lumen.example/a b",
        "https://.example",
        "https://lumen.",
    ])
    func otherURLsAreInvalid(url: String) {
        #expect(!ListingFieldValidator.isValidURL(url))
        let validation = ListingFieldValidator.validate(url, for: .marketingURL)
        #expect(validation == .invalidURL)
        #expect(validation.isBlocking)
        #expect(validation.message == "Use a full https:// address.")
    }

    // MARK: - Counter

    @Test func counterText() {
        let name = ListingFieldCounter("Lumen: Tagebuch", limit: ListingTextLimit(30))
        #expect(name.text == "15 / 30")
        #expect(name.accessibilityLabel == "15 of 30 characters")
        #expect(!name.isOverLimit)
        let keywords = ListingFieldCounter(String(repeating: "ü", count: 57), limit: ListingTextLimit(100, unit: .bytes))
        #expect(keywords.text == "114 / 100 bytes")
        #expect(keywords.isOverLimit)
        #expect(keywords.overBy == 14)
        #expect(keywords.accessibilityLabel == "Over the limit, 114 of 100 bytes")
    }

    /// A subscription's description takes 55: Alba's 54-character English
    /// one is live in App Store Connect, and was shown over a limit of 45.
    @Test func inAppTextLimits() {
        #expect(InAppTextField.subscriptionName.limit == ListingTextLimit(30))
        #expect(InAppTextField.subscriptionDescription.limit == ListingTextLimit(55))
        #expect(InAppTextField.purchaseName.limit == ListingTextLimit(30))
        #expect(InAppTextField.purchaseDescription.limit == ListingTextLimit(45))
        #expect(InAppTextField.subscriptionGroupName.limit == ListingTextLimit(30))
        let alba = "All premium backgrounds, plus new ones as they arrive."
        #expect(!ListingFieldValidator.validate(alba, for: .subscriptionDescription).isBlocking)
        #expect(ListingFieldValidator.validate(String(repeating: "x", count: 56), for: .subscriptionDescription).isBlocking)
        #expect(ListingFieldValidator.validate(String(repeating: "x", count: 46), for: .purchaseDescription).isBlocking)
    }
}
