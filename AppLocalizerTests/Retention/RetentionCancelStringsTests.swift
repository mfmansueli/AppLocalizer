//
//  RetentionCancelStringsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The preview's Confirm Cancellation words: every one of the 18
/// languages, right to left for Arabic and Hebrew, the end date in the
/// language, and an offer's line.
@Suite("Retention preview strings")
struct RetentionCancelStringsTests {
    @Test(arguments: RetentionLanguages.standard.map(\.code))
    func everyLanguageHasItsOwnWords(code: String) {
        let strings = RetentionCancelStrings.strings(for: code)
        #expect(strings.end.contains("{date}"))
        if !code.hasPrefix("en") {
            #expect(strings.title != RetentionCancelStrings.english.title)
            #expect(strings.cancel != RetentionCancelStrings.english.cancel)
        }
    }

    @Test func arabicAndHebrewReadRightToLeft() {
        #expect(RetentionCancelStrings.isRightToLeft("ar-SA"))
        #expect(RetentionCancelStrings.isRightToLeft("he"))
        #expect(!RetentionCancelStrings.isRightToLeft("de-DE"))
    }

    @Test func aLanguageWithoutItsOwnWordsReadsEnglish() {
        #expect(RetentionCancelStrings.strings(for: "fi") == .english)
        #expect(RetentionCancelStrings.strings(for: "en-GB") == .english)
    }

    @Test func theEndDateIsWrittenInTheLanguage() {
        let english = RetentionCancelStrings.english.endText(date: RetentionSampleData.endDate, code: "en-US")
        #expect(english == "If you cancel this subscription, your service will end on December 14, 2026.")
        let german = RetentionCancelStrings.strings(for: "de-DE").endText(date: RetentionSampleData.endDate, code: "de-DE")
        #expect(german.contains("14. Dezember 2026"))
    }

    @Test func anOffersLineSaysItsTerms() throws {
        let half = try #require(RetentionSampleData.offers.first)
        let line = RetentionCancelStrings.english.offerLine(half, basePrice: Decimal(string: "4.99"), period: .oneMonth)
        #expect(line == "3 months at 50% off, then $4.99/month")
        let free = RetentionSampleData.offers[1]
        #expect(RetentionCancelStrings.english.offerLine(free, basePrice: Decimal(string: "39.99"), period: .oneYear) == "1 month free, then $39.99/year")
    }
}
#endif
