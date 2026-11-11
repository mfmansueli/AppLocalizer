//
//  AutopilotRetryEveryLanguageTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Retry in Every Language: a change to the project that shows on a screen
/// in every language. Alba's topics menu covered the phrase on iPhone in all
/// 14 languages, Italian was reported, and Retry captured Italian alone.
@MainActor
@Suite("Autopilot retry in every language")
struct AutopilotRetryEveryLanguageTests {
    private let center = AutopilotTestFixtures.center()
    private let context: AutopilotContext
    private let appID = AutopilotTestFixtures.appID
    private static let fix = "AlbaUITests/Screenshots/ScreenshotUITests.swift:104: move the phrase above the menu."

    init() {
        context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// English, German and Japanese on iPhone and iPad, every screen
    /// captured an hour before the problems.
    private func installCaptured(locales: [String] = ["en-US", "de-DE", "ja"], except: Set<AutopilotCaptureTarget> = []) {
        var plan = AutopilotTestFixtures.smallPlan
        plan.localeCodes = locales
        var run = AutopilotTestFixtures.run(.capture, plan: plan)
        for (index, target) in plan.targets.enumerated() where !except.contains(target) {
            run.captures.append(AutopilotTestFixtures.capture(target, in: plan, second: index - 3600))
        }
        center.install(run)
    }

    private func report(_ locale: String, fix: String = Self.fix, changesProject: Bool? = true) throws -> AutopilotProblem {
        try center.reportProblem(
            appID: appID, target: AutopilotTestFixtures.target("week", .iPhone, locale),
            what: "The open menu covers the phrase.", proposedFix: fix, changesProject: changesProject
        )
    }

    @Test func theOtherLanguagesOfTheScreenOnItsDeviceAreCapturedAgain() async throws {
        installCaptured()
        let problem = try report("ja")
        let before = try #require(run)
        #expect(Set(before.otherLanguageTargets(of: problem).map(\.locale)) == ["en-US", "de-DE"])

        await center.retryInEveryLanguage(appID: appID, problemIDs: [problem.id], context: context)
        let run = try #require(run)
        let retried = run.retries.map(\.target)
        #expect(Set(retried) == [
            AutopilotTestFixtures.target("week", .iPhone, "ja"),
            AutopilotTestFixtures.target("week", .iPhone, "en-US"),
            AutopilotTestFixtures.target("week", .iPhone, "de-DE"),
        ])
        #expect(run.retries.allSatisfy { $0.proposedFix == Self.fix && $0.needsProjectChange })
        #expect(run.openProblems.isEmpty)
        #expect(!retried.contains { $0.displayType == .iPad }, "Only the reported device")
        #expect(!retried.contains { $0.screenID != "week" }, "Only the reported screen")
    }

    @Test func aCaptureThatArrivesAfterwardsSettlesItsLanguage() async throws {
        installCaptured()
        let problem = try report("ja")
        await center.retryInEveryLanguage(appID: appID, problemIDs: [problem.id], context: context)
        let german = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        center.update(appID) { run in
            run.captures.append(AutopilotTestFixtures.capture(german, attempt: 2, second: 3600))
        }
        let run = try #require(run)
        #expect(!run.retries.contains { $0.target == german })
        #expect(run.retries.contains { $0.target == AutopilotTestFixtures.target("week", .iPhone, "en-US") })
    }

    @Test func languagesNotCapturedYetAreLeftToTheRun() throws {
        installCaptured(except: [AutopilotTestFixtures.target("week", .iPhone, "de-DE")])
        let problem = try report("ja")
        let run = try #require(run)
        #expect(run.otherLanguageTargets(of: problem).map(\.locale) == ["en-US"])
    }

    @Test func theCardOffersItOnlyWhenOtherLanguagesHaveCaptures() throws {
        installCaptured(locales: ["en-US"])
        _ = try report("en-US")
        let run = try #require(run)
        let group = try #require(run.problemGroups.first)
        #expect(run.otherLanguageCount(of: group) == 0)
    }

    @Test func theCountLeavesOutLanguagesTheGroupAlreadyHas() throws {
        installCaptured()
        _ = try report("ja")
        _ = try report("de-DE")
        let run = try #require(run)
        let group = try #require(run.problemGroups.first)
        #expect(group.problems.count == 2)
        #expect(run.otherLanguageCount(of: group) == 1, "English only")
    }

    @Test func aDeviceWideProblemHasNoOtherLanguages() throws {
        installCaptured()
        let problem = try center.reportProblem(
            appID: appID, target: AutopilotTestFixtures.target("week", .iPad, "ja"),
            what: "This Mac has no iPad simulator.", proposedFix: nil, affectsDevice: true
        )
        let run = try #require(run)
        #expect(run.otherLanguageTargets(of: problem).isEmpty)
    }
}
#endif
