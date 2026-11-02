//
//  AutopilotRehearsalTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The rehearsal — every screen in the primary language and one other
/// first — and what a problem holds back, so a test that only works in
/// English fails once instead of in every language.
@MainActor
@Suite("Autopilot rehearsal")
struct AutopilotRehearsalTests {
    /// Two screens on iPhone and iPad in English, German and Japanese.
    private static var plan: AutopilotPlan {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = ["en-US", "de-DE", "ja"]
        return plan
    }

    private static func plan(_ locales: [String], primary: String = "en-US") -> AutopilotPlan {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = locales
        plan.primaryLocale = primary
        return plan
    }

    private func target(_ screen: String, _ display: ScreenshotDisplayType, _ locale: String) -> AutopilotCaptureTarget {
        AutopilotTestFixtures.target(screen, display, locale)
    }

    // MARK: - The language

    @Test func theRehearsalIsALanguageInAnotherScript() {
        #expect(Self.plan(["en-US", "de-DE", "fr-FR", "ko", "ja"]).rehearsalLocale == "ko")
        #expect(Self.plan(["en-US", "fr-FR", "ar-SA"]).rehearsalLocale == "ar-SA")
        #expect(Self.plan(["ja", "ko", "en-US"], primary: "ja").rehearsalLocale == "ko", "Korean isn't written in Japanese's script")
    }

    @Test func withTheSameScriptGermanIsRehearsedForItsLongWords() {
        #expect(Self.plan(["en-US", "fr-FR", "de-DE", "it"]).rehearsalLocale == "de-DE")
        #expect(Self.plan(["en-US", "fr-FR", "it"]).rehearsalLocale == "fr-FR")
    }

    @Test func oneLanguageHasNoRehearsal() {
        #expect(Self.plan(["en-US"]).rehearsalLocale == nil)
        var plan = Self.plan
        plan.capturesEachLanguage = false
        #expect(plan.rehearsalLocale == nil)
        #expect(plan.rehearsalFirstTargets == plan.targets)
    }

    @Test func scriptsComeFromTheLanguage() {
        #expect(AutopilotPlan.script(of: "en-US") == "Latn")
        #expect(AutopilotPlan.script(of: "ja") == "Jpan")
        #expect(AutopilotPlan.script(of: "zh-Hant") == "Hant")
        #expect(AutopilotPlan.script(of: "ru") == "Cyrl")
    }

    // MARK: - The order

    @Test func theRehearsalIsCapturedBeforeTheOtherLanguages() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        #expect(run.plan.rehearsalLocale == "ja")
        #expect(run.isRehearsing)
        #expect(run.remainingTargets.count == 12)
        #expect(Set(run.nextTargets.map(\.locale)) == ["en-US", "ja"])
        #expect(run.nextTargets.count == 8)
        #expect(Array(run.remainingTargets.prefix(8)) == run.nextTargets, "The rest comes after")

        let rehearsal = Set(run.nextTargets)
        AutopilotTestFixtures.captureAll(&run, except: Set(run.plan.targets).subtracting(rehearsal))
        #expect(!run.isRehearsing)
        #expect(run.nextTargets.map(\.locale) == Array(repeating: "de-DE", count: 4))
    }

    @Test func aScreenRehearsedGoesOnInTheOtherLanguagesWhileTheRestRehearses() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        run.captures = [
            AutopilotTestFixtures.capture(target("week", .iPhone, "en-US")),
            AutopilotTestFixtures.capture(target("week", .iPhone, "ja")),
        ]
        #expect(run.isRehearsing)
        #expect(run.nextTargets.count == 7)
        #expect(Array(run.nextTargets.prefix(6)).allSatisfy(run.plan.isRehearsal), "The rehearsal comes first")
        #expect(run.nextTargets.last == target("week", .iPhone, "de-DE"))
    }

    /// A device the assistant can't capture, and doesn't report, holds back
    /// only its own languages: the run's other devices go on.
    @Test func aDeviceThatCantGoOnHoldsBackOnlyItsOwnLanguages() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        let iPad = Set(run.plan.targets.filter { $0.displayType == .iPad })
        AutopilotTestFixtures.captureAll(&run, except: iPad.union(run.plan.targets.filter { $0.locale == "de-DE" }))
        #expect(run.isRehearsing)
        #expect(Set(run.nextTargets) == Set([
            target("today", .iPad, "en-US"), target("today", .iPad, "ja"), target("week", .iPad, "en-US"), target("week", .iPad, "ja"),
            target("today", .iPhone, "de-DE"), target("week", .iPhone, "de-DE"),
        ]))
        #expect(!run.nextTargets.contains(target("today", .iPad, "de-DE")))
    }

    // MARK: - Holds

    @Test func aProblemHoldsItsScreenOnItsDeviceInTheOtherLanguages() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        let japanese = target("week", .iPhone, "ja")
        run.problems = [AutopilotTestFixtures.problem(japanese)]

        #expect(run.heldTargets == [japanese, target("week", .iPhone, "de-DE")])
        #expect(!run.remainingTargets.contains(target("week", .iPhone, "de-DE")))
        #expect(run.remainingTargets.contains(target("week", .iPhone, "en-US")), "Not the primary language's")
        #expect(run.remainingTargets.contains(target("week", .iPad, "de-DE")), "Nor another device's")
        #expect(run.nextTargets.count == 7, "The rest of the rehearsal goes on")
    }

    @Test func aProblemInThePrimaryLanguageHoldsEveryLanguage() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        run.problems = [AutopilotTestFixtures.problem(target("today", .iPad, "en-US"))]
        #expect(run.heldTargets == [target("today", .iPad, "en-US"), target("today", .iPad, "de-DE"), target("today", .iPad, "ja")])
    }

    @Test func aRetryHoldsTheOtherLanguagesUntilItsCaptureArrives() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        let japanese = target("week", .iPhone, "ja")
        run.problems = [AutopilotTestFixtures.problem(japanese, resolution: .retryWithFix)]
        #expect(run.retries.map(\.id) == ["pr-1"])
        #expect(run.remainingTargets.contains(japanese), "The retried screen is captured again")
        #expect(run.heldTargets == [target("week", .iPhone, "de-DE")])

        run.captures = [AutopilotTestFixtures.capture(japanese)]
        #expect(run.heldTargets.isEmpty)
        #expect(run.retries.isEmpty)
    }

    @Test func aRetryReportedAgainIsAProblemAgainNotARetry() {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        let japanese = target("week", .iPhone, "ja")
        run.problems = [
            AutopilotTestFixtures.problem(japanese, id: "pr-1", resolution: .retryWithFix),
            AutopilotTestFixtures.problem(japanese, id: "pr-2"),
        ]
        #expect(run.retries.isEmpty)
        #expect(run.openProblems.map(\.id) == ["pr-2"])
        #expect(run.heldTargets.contains(target("week", .iPhone, "de-DE")))
    }

    // MARK: - The primary capture for every language

    @Test func thePrimaryCaptureCanStandInForEveryOtherLanguage() throws {
        var run = AutopilotTestFixtures.run(.capture, plan: Self.plan)
        let german = target("week", .iPhone, "de-DE")
        run.captures = [AutopilotTestFixtures.capture(german)]
        run.usePrimaryCapture(screenID: "week", on: .iPhone)

        #expect(run.primaryCaptureTargets == [target("week", .iPhone, "ja")], "German has its own capture")
        #expect(run.isSettled(target("week", .iPhone, "ja")))
        #expect(!run.isSettled(target("week", .iPhone, "en-US")))
        #expect(!run.isSettled(target("week", .iPad, "ja")))

        let decoded = try JSONDecoder().decode(AutopilotRun.self, from: JSONEncoder().encode(run))
        #expect(decoded.primaryCaptureTargets == run.primaryCaptureTargets)
    }

    @Test func aRunFromBeforeHasNoStandIns() throws {
        let run = AutopilotTestFixtures.run(.capture)
        let json = try #require(String(data: JSONEncoder().encode(run), encoding: .utf8))
        #expect(!json.contains("primaryCaptureTargets"))
        #expect(try JSONDecoder().decode(AutopilotRun.self, from: Data(json.utf8)).primaryCaptureTargets == nil)
    }
}
#endif
