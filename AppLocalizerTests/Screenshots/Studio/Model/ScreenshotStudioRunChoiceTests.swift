//
//  ScreenshotStudioRunChoiceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's "What this run makes" and "+ Add a Screen…" in the Studio:
/// presets, each line the card says, and the form's screen.
@MainActor
@Suite("ScreenshotStudioModel · what this run makes")
struct ScreenshotStudioRunChoiceTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    /// Lumen's plan after a run whose captures and picks it can reuse.
    private static var reusablePlan: AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        run.keptFrom = AutopilotKeptCaptures(
            versionString: "1.3", capturedAt: StudioDebugRuns.date(day: 28, month: 10, hour: 9), displayTypes: [.iPhone, .iPad],
            localeCount: 12, hasPicks: true
        )
        return run
    }

    /// The Screenshots view model (the Studio holds it unowned) and its
    /// center.
    private func screenshots(_ run: AutopilotRun = reusablePlan) async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(run)
        return await (StudioTestFixtures.screenshots(center: center), center)
    }

    @Test func aPresetSetsTheRowsAndAnEditMakesItCustom() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        #expect(try studio.runPreset(#require(center.run(for: appID)?.plan)) == .screenshots)

        studio.applyPreset(.headerAndSearch)
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(studio.runPreset(plan) == .headerAndSearch)
        #expect(plan.reusesCaptures, "The last captures are there to reuse")

        studio.setPreviews(.iPhone, true)
        studio.updatePlan { $0.alsoMakes.makesAppPreview = true }
        #expect(try studio.runPreset(#require(center.run(for: appID)?.plan)) == .custom)
    }

    @Test func theSummarySaysWhatTheRunMakes() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(studio.runSummaryText(plan) == "This run makes \(15 * 12) screenshots for \(plan.devicesTitle) in 12 languages. Everything else on the App Store stays as it is.")

        studio.updatePlan { plan in
            plan.runChoice.makesScreenshots = false
            plan.alsoMakes.makesArtwork = true
            plan.alsoMakes.makesAppPreview = true
        }
        let extras = try #require(center.run(for: appID)?.plan)
        #expect(ScreenshotStudioModel.runMakes(extras)
            == "header and search artwork and an App Preview for iPhone and iPad in 12 languages (the App Preview in English (U.S.) only)")

        studio.updatePlan { $0.alsoMakes.makesArtwork = false }
        let previewOnly = try #require(center.run(for: appID)?.plan)
        #expect(ScreenshotStudioModel.runMakes(previewOnly) == "an App Preview for iPhone and iPad in English (U.S.)")

        studio.updatePlan { $0.alsoMakes.makesAppPreview = false }
        let nothing = try #require(center.run(for: appID)?.plan)
        #expect(studio.runSummaryText(nothing) == "Nothing selected. Turn on at least one row.")
    }

    @Test func theRowsSayWhatStaysLive() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        let plan = try #require(center.run(for: appID)?.plan)
        #expect(studio.screenshotsRowDetail(plan) == "15 screens per language")
        #expect(studio.appPreviewRowDetail(plan) == "Off · any live App Preview stays")
        #expect(studio.artworkRowDetail(plan) == "Off · any live artwork stays")

        studio.setMakesScreenshots(false)
        #expect(try studio.screenshotsRowDetail(#require(center.run(for: appID)?.plan)) == "Off · the live screenshots stay as they are")
    }

    @Test func theCapturesNoteSaysWhatReusingMeans() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        #expect(studio.reuseTitle == "Reuse \(StudioDebugRuns.date(day: 28, month: 10, hour: 9).formatted(.dateTime.month(.abbreviated).day())) captures")
        let fresh = try studio.capturesNote(#require(center.run(for: appID)?.plan), client: "Claude Code")
        #expect(fresh.hasPrefix("Claude Code runs this build and captures again, so the screens match"))

        studio.setReusesCaptures(true)
        let reused = try studio.capturesNote(#require(center.run(for: appID)?.plan), client: "Claude Code")
        #expect(reused.hasPrefix("Version 1.3 · iPhone and iPad in 12 languages, with your picks. Faster, but shows the app as it was on"))
        #expect(reused.hasSuffix("iPhone Duo has no earlier captures, so it’s captured now."))

        studio.setMakesScreenshots(false)
        #expect(try studio.capturesNote(#require(center.run(for: appID)?.plan), client: "Claude Code")
            == "Not needed: this run makes no screenshots or artwork.")
    }

    @Test func choosingLanguagesKeepsThePrimary() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        studio.setLanguageMode(.primary)
        #expect(center.run(for: appID)?.plan.localeCodes == ["en-US"])
        #expect(try studio.runLanguagesTitle(#require(center.run(for: appID)?.plan)) == "English (U.S.)")
        studio.setChooses("de-DE", true)
        #expect(center.run(for: appID)?.plan.localeCodes == ["en-US", "de-DE"])
        studio.setLanguageMode(.all)
        #expect(center.run(for: appID)?.plan.localeCodes.count == 12)
    }

    // MARK: - Add a Screen

    @Test func theFormAddsAScreenAfterThePlansMarkedAsThePersons() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        studio.openScreenForm()
        #expect(studio.screenDraft == AutopilotScreenDraft())
        studio.screenDraft?.name = "Insights"
        studio.addDraftScreen()

        let added = try #require(center.run(for: appID)?.plan.screens.last)
        #expect(added == AutopilotScreen(id: "insights", name: "Insights", origin: .person, worksOutSteps: true))
        #expect(studio.screenDraft == nil)
        #expect(studio.addScreensNote.hasPrefix("New screens go after screen 6 on iPhone and iPad."))
    }

    @Test func tenScreensDisableAdding() async {
        var full = Self.reusablePlan
        for index in 6...10 { full.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        let (model, center) = await screenshots(full)
        let studio = model.studio
        #expect(studio.plansMaximumScreens)
        #expect(studio.addScreensNote == "Apple allows up to 10 screenshots per device. Remove a screen to add another.")
        studio.screenDraft = AutopilotScreenDraft(name: "Insights")
        studio.addDraftScreen()
        #expect(center.run(for: appID)?.plan.screens.count == 10)
    }

    @Test func theSuggestionsTitleSaysWhatWasAskedFor() async {
        let (model, _) = await screenshots()
        let studio = model.studio
        let asked = StudioDebugAddScreens.suggested(ask: "one that shows the streak").screenSuggestions
        let open = StudioDebugAddScreens.suggested(ask: nil).screenSuggestions
        #expect(asked.map(studio.suggestionsTitle) == "For “one that shows the streak”")
        #expect(open.map(studio.suggestionsTitle) == "Screens Lumen Journal’s set is missing")
        #expect(studio.suggestBusyText(client: "Claude Code").hasPrefix("Claude Code is reading LumenUITests, the "))
    }
}
#endif
