//
//  AutopilotTextCheckTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What a capture's text says about it: which facts are a problem, how they
/// rank captures, and the ones the set still uses.
@MainActor
@Suite("Autopilot text check")
struct AutopilotTextCheckTests {
    private static func capture(
        _ locale: String, screen: String = "today", attempt: Int = 1, score: Double = 0.9, text: CaptureTextFacts?
    ) -> AutopilotCapture {
        AutopilotCapture(
            id: "\(locale)-\(screen)-\(attempt)", target: AutopilotCaptureTarget(screenID: screen, displayType: .iPhone, locale: locale),
            attempt: attempt, score: score, notes: "", captureID: "png-\(locale)-\(attempt)", pixelSize: ScreenshotDisplayType.iPhone.portraitPixelSize,
            receivedAt: AutopilotTestFixtures.now, text: text
        )
    }

    private static var run: AutopilotRun {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = ["en-US", "de-DE", "ja", "fr-FR"]
        return AutopilotTestFixtures.run(.pick, plan: plan)
    }

    @Test func aCaptureThatReadsAsEnglishOrThePrimaryLanguageIsInTheWrongOne() {
        let run = Self.run
        let today = run.plan.screens[0].id
        #expect(run.textIssues(of: Self.capture("ja", screen: today, text: CaptureTextFacts(language: "en")))
            == [.otherLanguage(found: "English", expected: "Japanese")])
        #expect(run.textIssues(of: Self.capture("de-DE", screen: today, text: CaptureTextFacts(language: "de"))).isEmpty)
        // French text in a German capture isn't a fallback: no flag.
        #expect(run.textIssues(of: Self.capture("de-DE", screen: today, text: CaptureTextFacts(language: "fr"))).isEmpty)
        #expect(run.textIssues(of: Self.capture("en-US", screen: today, text: CaptureTextFacts(language: "en"))).isEmpty)
        #expect(run.textIssues(of: Self.capture("ja", screen: today, text: nil)).isEmpty)
    }

    @Test func cutOffLabelsCountBeyondThePrimaryLanguages() {
        var run = Self.run
        let today = run.plan.screens[0].id
        let placeholder = CaptureTextFacts(language: "en", truncatedLines: ["Write something…"])
        run.captures = [Self.capture("en-US", screen: today, text: placeholder)]
        let german = Self.capture("de-DE", screen: today, text: CaptureTextFacts(language: "de", truncatedLines: ["Schreib etwas…"]))
        #expect(run.textIssues(of: german).isEmpty, "The primary language has the same placeholder")
        let cut = Self.capture("de-DE", screen: today, text: CaptureTextFacts(language: "de", truncatedLines: ["Schreib etwas…", "Wochenübersi…"]))
        #expect(run.textIssues(of: cut) == [.cutOff(["Schreib etwas…", "Wochenübersi…"])])
    }

    @Test func aSystemPromptIsAnIssueInAnyLanguage() {
        let run = Self.run
        let prompt = CaptureTextFacts(language: "en", promptLine: "“Lumen” Would Like to Send You Notifications")
        #expect(run.textIssues(of: Self.capture("en-US", screen: run.plan.screens[0].id, text: prompt))
            == [.systemPrompt("“Lumen” Would Like to Send You Notifications")])
    }

    @Test func aCleanCaptureRanksAboveABetterScoredOneWithAnIssue() {
        var run = Self.run
        let today = run.plan.screens[0].id
        let flagged = Self.capture("ja", screen: today, attempt: 1, score: 0.95, text: CaptureTextFacts(language: "en"))
        let clean = Self.capture("ja", screen: today, attempt: 2, score: 0.6, text: CaptureTextFacts(language: "ja"))
        run.captures = [flagged, clean]
        let target = AutopilotCaptureTarget(screenID: today, displayType: .iPhone, locale: "ja")
        #expect(run.captures(for: target).map(\.id) == [clean.id, flagged.id])
        #expect(run.finalCapture(for: target)?.id == clean.id)
        #expect(run.capturesToCheck.isEmpty)
    }

    @Test func thePickedAttemptIsKeptUnlessItsTextHasAnIssue() {
        var run = Self.run
        let today = run.plan.screens[0].id
        run.captures = [
            Self.capture("en-US", screen: today, attempt: 1, score: 0.9, text: nil),
            Self.capture("en-US", screen: today, attempt: 2, score: 0.5, text: nil),
            Self.capture("ja", screen: today, attempt: 1, score: 0.9, text: nil),
            Self.capture("ja", screen: today, attempt: 2, score: 0.5, text: CaptureTextFacts(language: "en")),
        ]
        run.picks[today] = "en-US-\(today)-2"
        let target = AutopilotCaptureTarget(screenID: today, displayType: .iPhone, locale: "ja")
        #expect(run.finalCapture(for: target)?.attempt == 1, "Attempt 2 is in English, so the clean one is used")
        run.captures[3].text = CaptureTextFacts(language: "ja")
        #expect(run.finalCapture(for: target)?.attempt == 2)
    }

    @Test func theSampleRunHasTwoCapturesToCheck() throws {
        let run = StudioDebugRuns.run(.pick)
        let toCheck = run.capturesToCheck
        #expect(toCheck.map(\.target.locale) == ["de-DE", "ja"])
        let japanese = try #require(toCheck.last)
        #expect(AutopilotCapturesToCheck.place(of: japanese, in: run) == "Japanese · Week · iPhone")
        #expect(japanese.issues.map(\.message) == ["Most of its text is in English, not Japanese."])
        #expect(toCheck.first?.issues.map(\.message) == ["Cut-off text: “Einträge durchsu…”."])
        #expect(AutopilotCapturesToCheck.title(count: 2) == "2 captures to check")
        #expect(AutopilotCapturesToCheck.title(count: 1) == "1 capture to check")
    }

    @Test func eachIssueTellsTheAssistantWhatToDo() {
        #expect(CaptureTextIssue.otherLanguage(found: "English", expected: "Japanese").fix.contains("sample data in Japanese"))
        #expect(CaptureTextIssue.systemPrompt("x").fix.contains("xcrun simctl privacy"))
        #expect(CaptureTextIssue.cutOff(["a…", "b…", "c…", "d…"]).message == "Cut-off text: “a…”, “b…”, “c…” and 1 more.")
    }

    @Test func aCaptureFromBeforeTheTextCheckStillReads() throws {
        let capture = Self.capture("ja", text: nil)
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(capture)) as? [String: Any])
        json["text"] = nil
        let decoded = try JSONDecoder().decode(AutopilotCapture.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(decoded.text == nil)
        #expect(decoded.id == capture.id)
    }
}
#endif
