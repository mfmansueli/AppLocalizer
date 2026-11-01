//
//  StudioSetSummaryBuilderTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Live set / New set card under the preview.
@MainActor
@Suite("StudioSetSummaryBuilder")
struct StudioSetSummaryBuilderTests {
    private static let finishedAt = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 31)

    // MARK: - Live

    @Test func theLiveSetCountsLanguagesWithTheirOwnScreenshots() {
        var builder = StudioTestFixtures.builder()
        builder.storeTexts = StudioTestFixtures.storeTexts(ScreenshotsSampleData.liveLocales + ["en-GB", "ar-SA", "nl-NL"])
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        #expect(summary.title == "Live set")
        #expect(summary.pill == "Live")
        #expect(summary.pillStyle == .neutral)
        #expect(summary.lines.map(\.label) == ["Made", "Languages", "iPad", "iPhone Duo", "Screenshots"])
        let missing = ["Arabic", "Dutch"].formatted(.list(type: .and))
        #expect(Self.value(summary, "Languages") == "9 of 11; \(missing) show English")
        #expect(Self.value(summary, "iPad") == "Own screenshots in 9 of 11 languages")
        #expect(Self.value(summary, "iPhone Duo") == "None yet: required from April 2027")
        #expect(Self.value(summary, "Screenshots") == "5 on iPhone in English")
        // English (U.K.)'s set was uploaded by hand.
        #expect(Self.value(summary, "Made") == "By hand, in App Store Connect")
    }

    @Test func pastThreeMissingLanguagesTheRestAreCounted() {
        var builder = StudioTestFixtures.builder()
        builder.storeTexts = StudioTestFixtures.storeTexts(["en-US", "ar-SA", "nl-NL", "sv", "da", "fi"])
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        let missing = ["Arabic", "Dutch", "Swedish", "2 more"].formatted(.list(type: .and))
        #expect(Self.value(summary, "Languages") == "1 of 6; \(missing) show English")
    }

    @Test func withoutStoreTextsOnlyThePrimaryLanguageCounts() {
        let summary = StudioSetSummaryBuilder(preview: StudioTestFixtures.builder(), templateVersion: 4, captureCount: 30).summary()
        #expect(Self.value(summary, "Languages") == "1 of 1")
    }

    @Test func aSetMadeOnlyFromTheTemplateSaysSo() {
        var builder = StudioTestFixtures.builder()
        builder.live = StudioTestFixtures.templateOnlyLive
        builder.matrix = StudioTestFixtures.matrix(live: StudioTestFixtures.templateOnlyLive)
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        #expect(Self.value(summary, "Made") == "With AppLocalizer’s template")
    }

    @Test func nothingLiveSaysSoOnEveryLine() {
        var builder = StudioTestFixtures.builder()
        builder.live = LiveScreenshots()
        builder.matrix = StudioTestFixtures.matrix(live: LiveScreenshots())
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        #expect(Self.value(summary, "Made") == "Nothing live yet")
        #expect(Self.value(summary, "Languages") == "None yet")
        #expect(Self.value(summary, "iPad") == "None: the App Store shows the iPhone set")
        #expect(Self.value(summary, "Screenshots") == "0 on iPhone in English")
    }

    // MARK: - New

    @Test func theNewSetWithoutARunCountsCaptures() throws {
        let builder = StudioTestFixtures.builder(choice: .new)
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        let name = try #require(StudioTestFixtures.templateName)
        #expect(summary.title == "New set")
        #expect(summary.pill == "Not pushed")
        #expect(summary.pillStyle == .accent)
        #expect(summary.lines.map(\.label) == ["Design", "Captures", "Screenshots", "Checks"])
        #expect(Self.value(summary, "Design") == "\(name) · template v4")
        #expect(Self.value(summary, "Captures") == "30 captures")
        let displays = ["iPhone", "iPad"].formatted(.list(type: .and))
        #expect(Self.value(summary, "Screenshots") == "40 · \(displays) · 12 languages")
        #expect(Self.value(summary, "Checks") == "2 fail their checks")
    }

    @Test func oneCaptureIsSingular() {
        let summary = StudioSetSummaryBuilder(preview: StudioTestFixtures.builder(choice: .new), templateVersion: nil, captureCount: 1).summary()
        #expect(Self.value(summary, "Captures") == "1 capture")
        #expect(Self.value(summary, "Design") == StudioTestFixtures.templateName)
    }

    @Test func aReadyRunNamesItsDirectionAndAssistant() {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.run = StudioDebugRuns.run(.ready)
        let now = Self.finishedAt.addingTimeInterval(2 * 3600)
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30, now: now).summary()
        #expect(Self.value(summary, "Design") == "Quiet Indigo · template v4 · Claude Design")
        #expect(Self.value(summary, "Captures") == "Claude Code in Simulator · 2 hours ago")
    }

    @Test func aFinishInTheFutureReadsNow() throws {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.run = StudioDebugRuns.run(.ready)
        let now = Self.finishedAt.addingTimeInterval(-2 * 3600)
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30, now: now).summary()
        let captures = try #require(Self.value(summary, "Captures"))
        #expect(captures == "Claude Code in Simulator · now")
        #expect(!captures.contains("in 2 hours"))
    }

    @Test func aRunThatIsntReadyDoesntDescribeTheNewSet() throws {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.matrix = StudioTestFixtures.matrix(failing: 0)
        builder.run = StudioDebugRuns.run(.localize)
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        let name = try #require(StudioTestFixtures.templateName)
        #expect(Self.value(summary, "Design") == "\(name) · template v4")
        #expect(Self.value(summary, "Captures") == "30 captures")
        #expect(Self.value(summary, "Checks") == "All fit")
    }

    @Test(arguments: [
        (0, 0, "All fit"),
        (0, 1, "All fit after 1 caption was shortened"),
        (0, 3, "All fit after 3 captions were shortened"),
        (1, 1, "1 fails its check"),
        (2, 0, "2 fail their checks"),
    ])
    func checksPutFailuresBeforeShortenedCaptions(failing: Int, shortened: Int, expected: String) {
        var builder = StudioTestFixtures.builder(choice: .new)
        builder.matrix = StudioTestFixtures.matrix(failing: failing)
        var run = StudioDebugRuns.run(.ready)
        run.shortenings = (0..<shortened).map { slot in
            AutopilotShortening(locale: "de-DE", slot: slot, before: "Long", after: "Short", client: "Claude Code")
        }
        builder.run = run
        let summary = StudioSetSummaryBuilder(preview: builder, templateVersion: 4, captureCount: 30).summary()
        #expect(Self.value(summary, "Checks") == expected)
    }

    // MARK: - Helpers

    private static func value(_ summary: StudioSetSummary, _ label: String) -> String? {
        summary.lines.first { $0.label == label }?.value
    }
}
#endif
