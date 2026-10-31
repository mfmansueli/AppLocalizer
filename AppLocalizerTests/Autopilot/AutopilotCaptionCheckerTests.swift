//
//  AutopilotCaptionCheckerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Laying a language's captions out with a direction: the ones too long or
/// missing go to the assistant, and a direction's pills say how the
/// languages fare.
@MainActor
@Suite("Autopilot caption checker")
struct AutopilotCaptionCheckerTests {
    private static let tooLong = String(repeating: "Tagebucheinträge durchsuchen ", count: 12)

    /// Short captions in every one of `locales`, over five slots.
    private static func shortCaptions(_ locales: [String]) -> CaptionBook {
        let words = ["en-US": "Journal", "de-DE": "Tagebuch", "ar-SA": "مذكرات", "ja": "日記", "ko": "일기", "fr-FR": "Journal", "it": "Diario"]
        var book = CaptionBook()
        for locale in locales {
            for slot in 0..<5 {
                book.setCaption(ScreenshotCaption(headline: words[locale] ?? "Journal"), locale: locale, slot: slot)
            }
        }
        return book
    }

    private func checker(_ captions: CaptionBook, displayTypes: [ScreenshotDisplayType] = [.iPhone, .iPad]) -> AutopilotCaptionChecker {
        AutopilotCaptionChecker(
            template: ScreenshotTemplate.starter(.above, id: "lumen", title: "Lumen Journal"), captions: captions,
            displayTypes: displayTypes, slotCount: 5, primaryLocale: "en-US", catalog: ScreenshotsTestFixtures.fonts
        )
    }

    @Test func shortCaptionsFit() {
        let checker = checker(Self.shortCaptions(["en-US", "ar-SA", "ja"]))
        #expect(checker.check(locale: "en-US") == AutopilotLocaleCheck(status: .fits(note: nil), overflows: []))
        let arabic = checker.check(locale: "ar-SA")
        #expect(arabic.status.isDone)
        #expect(arabic.overflows.isEmpty)
        #expect(checker.check(locale: "ja").status.isDone)
    }

    @Test func anUnknownLanguageIsLeftAlone() {
        #expect(checker(CaptionBook()).check(locale: "xx-YY") == AutopilotLocaleCheck(status: .fits(note: nil), overflows: []))
    }

    @Test func aMissingTranslationIsOneOverflowPerSlot() {
        let check = checker(Self.shortCaptions(["en-US"])).check(locale: "de-DE")
        #expect(check.status == .shortening(count: 5))
        #expect(check.overflows.map(\.slot) == [0, 1, 2, 3, 4])
        #expect(check.overflows.allSatisfy { $0.headline.isEmpty && $0.fill == 0 && $0.displayType == .iPhone && $0.locale == "de-DE" })
    }

    @Test func theMissingPrimaryCaptionIsntTheAssistantsToWrite() {
        #expect(checker(CaptionBook()).check(locale: "en-US").overflows.isEmpty)
    }

    @Test func aCaptionTooLongIsSentWithHowMuchItNeeds() throws {
        var captions = Self.shortCaptions(["en-US", "de-DE"])
        captions.setCaption(ScreenshotCaption(headline: Self.tooLong, subhead: "Alles an einem Ort"), locale: "de-DE", slot: 2)
        let check = checker(captions).check(locale: "de-DE")

        #expect(check.status == .shortening(count: 1))
        let overflow = try #require(check.overflows.first)
        #expect(overflow.slot == 2)
        #expect(overflow.headline == Self.tooLong)
        #expect(overflow.subhead == "Alles an einem Ort")
        #expect(overflow.fill > 1)
        #expect(overflow.maxLines >= 1)
    }

    // MARK: - Direction pills

    @Test func aDirectionThatFitsEverywhereSaysSoWithRightToLeftAndCJK() {
        let locales = ["en-US", "ar-SA", "ja", "ko"]
        #expect(checker(Self.shortCaptions(locales)).directionChecks(locales: locales) == [
            AutopilotDirectionCheck(kind: .fitsAll, locale: nil, count: 4),
            AutopilotDirectionCheck(kind: .mirrors, locale: "ar-SA", count: 0),
            AutopilotDirectionCheck(kind: .fits, locale: "ja", count: 0),
        ])
    }

    @Test func missingTranslationsArentTooLong() {
        #expect(checker(Self.shortCaptions(["en-US"])).directionChecks(locales: ["en-US", "th"]) == [
            AutopilotDirectionCheck(kind: .fitsAll, locale: nil, count: 2),
        ])
    }

    @Test func atMostTwoLanguagesTooLongAreNamed() {
        let locales = ["en-US", "de-DE", "fr-FR", "it", "ja", "ko"]
        var captions = Self.shortCaptions(locales)
        for locale in ["de-DE", "fr-FR", "it", "ja"] {
            captions.setCaption(ScreenshotCaption(headline: Self.tooLong), locale: locale, slot: 0)
        }
        captions.setCaption(ScreenshotCaption(headline: Self.tooLong), locale: "de-DE", slot: 4)

        #expect(checker(captions, displayTypes: [.iPhone]).directionChecks(locales: locales) == [
            AutopilotDirectionCheck(kind: .tooLong, locale: "de-DE", count: 2),
            AutopilotDirectionCheck(kind: .tooLong, locale: "fr-FR", count: 1),
            AutopilotDirectionCheck(kind: .fits, locale: "ko", count: 0),
        ])
    }

    // MARK: - Titles

    @Test(arguments: [
        (AutopilotDirectionCheck(kind: .tooLong, locale: "de-DE", count: 1), "German: 1 caption too long, will be shortened"),
        (AutopilotDirectionCheck(kind: .tooLong, locale: "zh-Hans", count: 3), "Chinese: 3 captions too long, will be shortened"),
        (AutopilotDirectionCheck(kind: .fitsAll, locale: nil, count: 12), "Fits all 12 languages"),
        (AutopilotDirectionCheck(kind: .mirrors, locale: "ar-SA", count: 0), "Arabic mirrors"),
        (AutopilotDirectionCheck(kind: .fits, locale: "ja", count: 0), "Japanese fits"),
        (AutopilotDirectionCheck(kind: .fits, locale: "xx", count: 0), "xx fits"),
    ])
    func pillsReadAsTheDesignWritesThem(check: AutopilotDirectionCheck, title: String) {
        #expect(check.title == title)
        #expect(check.style == (check.kind == .tooLong ? .warning : .neutral))
    }
}
#endif
