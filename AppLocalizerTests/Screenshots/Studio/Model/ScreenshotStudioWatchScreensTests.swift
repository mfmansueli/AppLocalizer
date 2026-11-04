//
//  ScreenshotStudioWatchScreensTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// "+ Add a Screen…" and Suggest Screens under the plan's Apple Watch
/// screens, in the Studio: the form adds to the watch, each device keeps
/// what was asked, and the texts say the watch.
@MainActor
@Suite("ScreenshotStudioModel · Apple Watch screens")
struct ScreenshotStudioWatchScreensTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    private func screenshots(_ run: AutopilotRun = StudioDebugRuns.run(.plan, everyDevice: true)) async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(run)
        return await (StudioTestFixtures.screenshots(center: center), center)
    }

    @Test func theWatchsFormAddsAfterTheWatchsScreens() async throws {
        let (model, center) = await screenshots()
        let studio = model.studio
        studio.openScreenForm(on: .watch)
        #expect(studio.screenDraft == AutopilotScreenDraft(displayType: .watch))
        studio.screenDraft?.name = "Mood history"
        studio.screenDraft?.caption = "Typed before"
        studio.addDraftScreen()

        let plan = try #require(center.run(for: appID)?.plan)
        #expect(plan.screens.count == 5, "The set's screens stay as they are")
        #expect(plan.screens(on: .watch).last == AutopilotScreen(id: "watch-mood-history", name: "Mood history", origin: .person, worksOutSteps: true))
        #expect(studio.screenDraft == nil)
        #expect(studio.addScreensNote(on: .watch).hasPrefix("New screens go after screen 5 on Apple Watch."))
        #expect(studio.addScreensNote.hasPrefix("New screens go after screen 5 on iPhone and iPad."))
    }

    @Test func eachDeviceKeepsWhatWasAskedFor() async {
        let (model, _) = await screenshots()
        let studio = model.studio
        studio.screenAsk = "one that shows the streak"
        studio.setScreenAsk("the complication", on: .watch)
        #expect(studio.screenAsk(on: .iPhone) == "one that shows the streak")
        #expect(studio.screenAsk(on: .watch) == "the complication")
        #expect(studio.screenAsk == "one that shows the streak")
    }

    @Test func aFullSetDoesntStopTheWatch() async {
        var run = StudioDebugRuns.run(.plan, everyDevice: true)
        for index in 6...10 { run.plan.appendScreen(AutopilotScreen(name: "Screen \(index)", steps: "launch"), on: .iPhone) }
        let (model, center) = await screenshots(run)
        let studio = model.studio
        #expect(studio.plansMaximumScreens)
        #expect(!studio.plansMaximumScreens(on: .watch))
        studio.screenDraft = AutopilotScreenDraft(name: "Mood history", displayType: .watch)
        studio.addDraftScreen()
        #expect(center.run(for: appID)?.plan.screens(on: .watch).count == 5)
    }

    @Test func theTextsSayTheWatch() async {
        let (model, _) = await screenshots()
        let studio = model.studio
        let watch = AutopilotScreenSuggestions(
            ask: nil, client: "Claude Code", items: StudioDebugAddScreens.watchSuggestions, receivedAt: AutopilotTestFixtures.now, displayType: .watch
        )
        #expect(studio.suggestionsTitle(watch) == "Apple Watch screens Lumen Journal is missing")
        #expect(studio.suggestBusyText(client: "Claude Code", on: .watch).hasPrefix("Claude Code is reading the watch app, its UI tests, the "))
        #expect(studio.uiTestsName(on: .watch) == "the watch app’s UI tests")
        #expect(studio.uiTestsName(on: .iPhone) == "LumenUITests")
    }
}
#endif
