//
//  GuidedMakeSummaryTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What to make's sentence, what Done says was sent, and the plan's time.
@MainActor
@Suite("GuidedMakeSummary")
struct GuidedMakeSummaryTests {
    @Test func oneThingInOneLanguage() {
        let plan = AutopilotTestFixtures.singlePlan()
        #expect(GuidedMakeSummary.sentence(plan) == "You’ll get 1 screenshot in English (U.S.).")
        #expect(GuidedMakeSummary.pushed(plan) == "1 screenshot")
    }

    @Test func everythingInEveryLanguage() {
        var plan = StudioDebugGuided.planned().plan
        plan.alsoMakes.previewLanguages = .all
        let count = plan.screensPerLanguage * plan.localeCodes.count
        let languages = plan.localeCodes.count
        #expect(GuidedMakeSummary.made(plan)
            == "\(count) screenshots, an App Preview in every language, and \(plan.artworkMadeTitle), in \(languages) languages")

        plan.alsoMakes.previewLanguages = .primary
        #expect(GuidedMakeSummary.made(plan)?.contains("an App Preview in English (U.S.)") == true)
        let previews = plan.previewDisplays.count * plan.previewLocales.count
        #expect(GuidedMakeSummary.pushed(plan)
            == "\(count) screenshots, \(previews) App Previews, and \(plan.artworkMadeTitle) in \(languages) languages")
    }

    /// MB Admin, Portuguese only: "an App Preview in Portuguese (Brazil),
    /// and header and search artwork, in Portuguese (Brazil)" said the
    /// language twice.
    @Test func oneLanguageIsSaidOnce() {
        var plan = StudioDebugGuided.planned().plan
        plan.localeCodes = [plan.primaryLocale]
        let name = GuidedMakeSummary.primaryName(plan)
        let made = GuidedMakeSummary.made(plan) ?? ""
        #expect(made.hasSuffix(", in \(name)"))
        #expect(made.contains("an App Preview, "))
        #expect(made.components(separatedBy: name).count == 2, "Once: \(made)")
    }

    @Test func nothingAsksForOneThing() {
        var plan = StudioDebugGuided.planned(screenshots: false, appPreview: false, artwork: false).plan
        plan.runChoice.previewDisplays = []
        #expect(GuidedMakeSummary.made(plan) == nil)
        #expect(GuidedMakeSummary.sentence(plan) == "Pick at least one thing to make.")
        #expect(GuidedMakeSummary.pushed(plan) == nil)
    }

    @Test func localizingTakesAMinuteForEveryFourLanguages() {
        var plan = AutopilotTestFixtures.smallPlan
        #expect(GuidedMakeSummary.localizeMinutes(plan) == 2, "Two at least")
        plan.localeCodes = (1...18).map { "xx-\($0)" }
        #expect(GuidedMakeSummary.localizeMinutes(plan) == 5)
    }

    @Test func keptCapturesTakeNoTime() {
        let plan = AutopilotTestFixtures.smallPlan
        let all = GuidedMakeSummary.minutes(plan, design: .none)
        let kept = GuidedMakeSummary.minutes(plan, design: .none, kept: plan.targets.count)
        #expect(kept < all)
        #expect(kept >= 1)
    }
}
#endif
