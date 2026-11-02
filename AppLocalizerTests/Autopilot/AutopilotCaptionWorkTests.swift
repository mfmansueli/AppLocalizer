//
//  AutopilotCaptionWorkTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The captions out to the assistant while localizing: missing ones (to
/// translate) told apart from ones too long, per language and in all, and
/// whether the assistant is on them.
@Suite("Autopilot caption work")
struct AutopilotCaptionWorkTests {
    private static func missing(_ locale: String, slots: Int) -> [AutopilotOverflow] {
        (0..<slots).map { AutopilotOverflow(locale: locale, slot: $0, displayType: .iPhone, headline: "", maxLines: 2, fill: 0) }
    }

    private static func tooLong(_ locale: String, slot: Int) -> AutopilotOverflow {
        AutopilotOverflow(locale: locale, slot: slot, displayType: .iPhone, headline: "Durchsuche jahrelange Einträge", maxLines: 2, fill: 1.3)
    }

    private static let overflows = missing("ja", slots: 5) + missing("ar-SA", slots: 5) + [tooLong("de-DE", slot: 2)]

    @Test func itCountsWhatsMissingAndWhatsTooLong() {
        let all = AutopilotCaptionWork(Self.overflows)
        #expect(all == AutopilotCaptionWork(missing: 10, tooLong: 1, languages: 3))
        #expect(all.total == 11)
        #expect(AutopilotCaptionWork(Self.overflows, locale: "ja") == AutopilotCaptionWork(missing: 5, tooLong: 0))
        #expect(AutopilotCaptionWork(Self.overflows, locale: "de-DE") == AutopilotCaptionWork(missing: 0, tooLong: 1))
        #expect(AutopilotCaptionWork([]).isEmpty)
        #expect(AutopilotCaptionWork(Self.overflows, locale: "fr-FR").isEmpty)
    }

    @Test func itSaysWhichIsWhich() {
        #expect(AutopilotCaptionWork(missing: 5, tooLong: 0).summary == "5 captions to translate")
        #expect(AutopilotCaptionWork(missing: 1, tooLong: 0).summary == "1 caption to translate")
        #expect(AutopilotCaptionWork(missing: 0, tooLong: 2).summary == "2 captions too long")
        #expect(AutopilotCaptionWork(missing: 0, tooLong: 1).summary == "1 caption too long")
        #expect(AutopilotCaptionWork(missing: 3, tooLong: 2).summary == "3 captions to translate, 2 too long")
    }

    @Test func aLanguagesRowSaysWhetherTheAssistantIsOnThem() {
        #expect(AutopilotCaptionWork(missing: 5, tooLong: 0).rowText(by: "Claude Code", isWorking: true)
            == "5 captions to translate · Claude Code is writing them")
        #expect(AutopilotCaptionWork(missing: 0, tooLong: 1).rowText(by: "Claude Code", isWorking: true)
            == "1 caption too long · Claude Code is shortening them")
        #expect(AutopilotCaptionWork(missing: 3, tooLong: 2).rowText(by: "Claude Code", isWorking: true)
            == "3 captions to translate, 2 too long · Claude Code is on them")
        #expect(AutopilotCaptionWork(missing: 5, tooLong: 0).rowText(by: "Claude Code", isWorking: false)
            == "5 captions to translate · waiting for Claude Code")
    }

    @Test func itSaysWhatTheAssistantIsDoing() {
        #expect(AutopilotCaptionWork(Self.overflows).doing(by: "Claude Code")
            == "Claude Code is translating 10 captions and shortening 1, in 3 languages.")
        #expect(AutopilotCaptionWork(Self.missing("ja", slots: 5)).doing(by: "Claude Code") == "Claude Code is translating 5 captions into 1 language.")
        #expect(AutopilotCaptionWork([Self.tooLong("de-DE", slot: 2)]).doing(by: "Claude Code") == "Claude Code is shortening 1 caption in 1 language.")
    }
}
#endif
