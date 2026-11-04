//
//  AutopilotWatchStageTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Watch the App Preview as a step of every run: the person's turn on the
/// strip, skipped when there's nothing to watch, and the assistant's turn
/// only while a change it can make waits.
@MainActor
@Suite("Autopilot · the Watch the App Preview step")
struct AutopilotWatchStageTests {
    private static func strip(_ run: AutopilotRun) -> AutopilotStripContent {
        AutopilotStripContent.make(run: run, appName: "Lumen Journal", assistant: "Claude Code", designProject: nil, hasNewSet: true)
    }

    @Test(arguments: [
        (true, "Watch the App Preview, then approve it or ask Claude Design for changes."),
        (false, "Watch the App Preview, then approve it."),
    ])
    func theStripSaysItsThePersonsTurn(design: Bool, text: String) {
        var run = AutopilotPreviewTestRun.run(.watchPreview)
        if !design { run.designKind = .none }
        let strip = Self.strip(run)
        #expect(strip.kind == .yourTurn)
        #expect(strip.pill == "Your turn")
        #expect(strip.text == text)
        #expect(strip.primary == .open)
    }

    @Test func itsSkippedWithoutAnAppPreviewOrTheStop() {
        var run = AutopilotPreviewTestRun.run(.plan)
        #expect(run.watchSkipNote == nil)
        run.plan.stopsToWatchPreview = false
        #expect(run.watchSkipNote == "Skipped: approved as made")
        run.plan.alsoMakes.makesAppPreview = false
        #expect(run.watchSkipNote == "Skipped · nothing moves in this run")
    }

    @Test func plansFromBeforeStopToWatch() throws {
        var plan = AutopilotPreviewTestRun.run(.plan).plan
        plan.stopsToWatch = nil
        #expect(plan.stopsToWatchPreview)
        let decoded = try JSONDecoder().decode(AutopilotPlan.self, from: JSONEncoder().encode(plan))
        #expect(decoded.stopsToWatchPreview)
        #expect(decoded.alsoMakes.previewMusic == .standard, "Warm acoustic for plans without music")
    }

    @Test func theAssistantWorksOnlyOnAChangeItCanMake() {
        var run = AutopilotPreviewTestRun.run(.watchPreview)
        #expect(!run.assistantHasWork, "The person is watching")
        run.previewReview?.request = AutopilotRevisionRequest(note: "Faster", askedAt: AutopilotTestFixtures.now)
        #expect(run.assistantHasWork)
        run.previewReview?.remake = AutopilotPreviewRemake(reason: .revision(2), total: 1)
        #expect(!run.assistantHasWork, "AppLocalizer is making it")
        run.previewReview?.remake = nil
        run.designKind = .none
        #expect(!run.assistantHasWork, "No design source to ask")
    }

    @Test func aReviewIsBusyWhileAChangeOrARemakeWaits() {
        var review = AutopilotPreviewReview()
        #expect(!review.isBusy)
        review.request = AutopilotRevisionRequest(note: "Faster", askedAt: AutopilotTestFixtures.now)
        #expect(review.isBusy)
        review.request = nil
        review.remake = AutopilotPreviewRemake(reason: .music("Calm piano"))
        #expect(review.isBusy)
    }

    @Test func theMusicIsNamed() {
        #expect(AutopilotPreviewMusic.standard.title == "Warm acoustic")
        #expect(AutopilotPreviewMusic(track: .brightPop).title == "Bright pop")
        let own = AutopilotPreviewMusic(fileID: "abc", fileExtension: "m4a", fileName: "lumen-theme.m4a")
        #expect(own.title == "Your file: lumen-theme.m4a")
        #expect(own.hasFile)
        #expect(!AutopilotPreviewMusic(track: .ownFile).hasFile)
        for track in AppPreviewTrack.library {
            #expect(track.isLibrary, "\(track)")
        }
        #expect(!AppPreviewTrack.ownFile.isLibrary)
    }
}
#endif
