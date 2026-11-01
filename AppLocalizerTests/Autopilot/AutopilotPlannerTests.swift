//
//  AutopilotPlannerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan Run Autopilot… opens with, and how long it says the run
/// takes.
@MainActor
@Suite("Autopilot planner and estimate")
struct AutopilotPlannerTests {
    private let standard = ScreenshotsDebugDocuments.standard

    @Test func aFirstPlanNamesTheDocumentsScreensWithTheirCaptions() throws {
        let plan = AutopilotPlanner.plan(
            document: standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["de-DE", "en-US", "ja"], previous: nil
        )
        #expect(plan.localeCodes == ["en-US", "de-DE", "ja"])
        #expect(plan.primaryLocale == "en-US")
        #expect(plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad])
        #expect(plan.screens.map(\.id) == ["today-1", "week-2", "search-3", "photos-4", "privacy-5"])
        #expect(plan.screens.map(\.name) == ScreenshotsSampleData.slotNames)
        #expect(plan.screens.map(\.steps) == Array(repeating: "", count: 5), "The assistant writes the steps")
        let caption = try #require(ScreenshotsTestFixtures.caption("en-US", slot: 0))
        #expect(plan.screens.first?.caption == caption.headline)
        #expect(plan.stopsToPick && plan.stopsToChoose && plan.capturesEachLanguage)
    }

    @Test func withOnlyThePrimaryLanguageTheDocumentsScopeIsUsed() {
        let plan = AutopilotPlanner.plan(
            document: standard, live: LiveScreenshots(), primaryLocale: .englishUS, localeCodes: [], previous: nil
        )
        #expect(plan.localeCodes.first == "en-US")
        #expect(Set(plan.localeCodes) == Set(ScreenshotsSampleData.scope))
        #expect(plan.localeCodes.count == ScreenshotsSampleData.scope.count)
    }

    @Test func runningAgainStartsFromTheLastPlan() {
        let previous = StudioDebugRuns.run(.ready)
        let plan = AutopilotPlanner.plan(
            document: standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US", "fr-FR"], previous: previous
        )
        #expect(plan.screens == previous.plan.screens)
        #expect(plan.writtenFrom == "LumenUITests/ScreenshotTests.swift")
        #expect(plan.simulator.sampleDataSteps == "Settings → Debug → Add Sample Week")
        #expect(plan.localeCodes == ["en-US", "fr-FR"])
    }

    @Test func withNothingToGoByThereAreNoScreens() {
        #expect(AutopilotPlanner.screens(from: nil, primary: "en-US").isEmpty)
        #expect(AutopilotPlanner.screens(from: .empty(primary: "en-US"), primary: "en-US").isEmpty)
        var named = ScreenshotsDocument.empty(primary: "en-US")
        named.slotNames = ["Today", "Week"]
        #expect(AutopilotPlanner.screens(from: named, primary: "en-US").map(\.name) == ["Today", "Week", "Slot 3", "Slot 4", "Slot 5"])
    }

    @Test func iPadIsPlannedWhenTheAppShowsItOrThereIsNothingToGoBy() {
        #expect(AutopilotPlanner.hasIPad(document: nil, live: LiveScreenshots()))
        #expect(AutopilotPlanner.hasIPad(document: standard, live: LiveScreenshots()))

        var phoneOnly = ScreenshotsDocument.empty(primary: "en-US")
        phoneOnly.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 0))
        #expect(!AutopilotPlanner.hasIPad(document: phoneOnly, live: LiveScreenshots()))

        let live = ScreenshotsDebugDocuments.live
        #expect(AutopilotPlanner.hasIPad(document: phoneOnly, live: live))
        let phoneSets = LiveScreenshots(screenshotSets: live.screenshotSets.filter { $0.displayType == .iPhone })
        #expect(!AutopilotPlanner.hasIPad(document: nil, live: phoneSets))
    }

    /// Apple requires iPhone Duo screenshots from April 2027: every plan
    /// has it, whatever the app shows or the project reports.
    @Test func iPhoneDuoIsPlannedForEveryApp() {
        #expect(AutopilotPlanner.devices(document: nil, live: LiveScreenshots(), support: .none) == [.iPhone, .iPhoneDuo, .iPad])
        #expect(AutopilotPlanner.devices(document: standard, live: ScreenshotsDebugDocuments.live, support: .none)
            == [.iPhone, .iPhoneDuo, .iPad])

        var phoneOnly = ScreenshotsDocument.empty(primary: "en-US")
        phoneOnly.captures.add(ScreenshotsSampleData.capture(locale: "en-US", display: .iPhone, slot: 0))
        #expect(AutopilotPlanner.devices(document: phoneOnly, live: LiveScreenshots(), support: .none) == [.iPhone, .iPhoneDuo])
    }

    @Test func iPhoneDuoJoinsALastPlanFromBeforeTheRuleUnlessItWasTurnedOff() {
        var previous = StudioDebugRuns.run(.ready)
        previous.plan.displayTypes = [.iPhone, .iPad]
        let plan = AutopilotPlanner.plan(
            document: standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US"], previous: previous
        )
        #expect(plan.displayTypes == [.iPhone, .iPhoneDuo, .iPad])

        var turnedOff = previous
        turnedOff.plan.setPlans(.iPhoneDuo, false)
        let again = AutopilotPlanner.plan(
            document: standard, live: ScreenshotsDebugDocuments.live, primaryLocale: .englishUS,
            localeCodes: ["en-US"], previous: turnedOff
        )
        #expect(!again.displayTypes.contains(.iPhoneDuo))
        #expect(again.leftOutDevices == [.iPhoneDuo])
    }

    // MARK: - Estimate

    @Test(arguments: [(0, 1), (1, 1), (8, 1), (40, 5), (120, 15)])
    func capturesTakeAboutSevenAndAHalfSecondsEach(captures: Int, minutes: Int) {
        #expect(AutopilotEstimate.captureMinutes(for: captures) == minutes)
    }

    @Test func theSummarySaysHowManyAndHowLong() {
        let plan = StudioDebugRuns.plan
        #expect(AutopilotEstimate.summary(for: plan, design: .claudeDesign)
            == "120 captures in 12 languages · about 15 min on this Mac, then about 3 min of design")
        #expect(AutopilotEstimate.summary(for: plan, design: .none, kept: 40)
            == "120 captures in 12 languages · about 10 min on this Mac, then about 1 min of design · 40 kept from the last run")
        #expect(AutopilotEstimate.summary(for: AutopilotTestFixtures.singlePlan(), design: .folder)
            == "1 capture in 1 language · about 1 min on this Mac, then about 3 min of design")

        var primaryOnly = plan
        primaryOnly.capturesEachLanguage = false
        #expect(AutopilotEstimate.summary(for: primaryOnly, design: .none).hasPrefix("10 captures in 1 language · "))
    }
}
#endif
