//
//  AutopilotResumeTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What stopped when AppLocalizer closed: a run left at Localize and check
/// with nothing for the assistant picks up and gets ready; one that closed
/// before the set was saved goes back to the choice; an App Preview being
/// mixed again is mixed again, and a revision's goes back to the design
/// source. Nothing starts twice, and a run that waits for someone stays.
@MainActor
@Suite("Autopilot resume after closing")
struct AutopilotResumeTests {
    private let center = AutopilotTestFixtures.center()
    private let services: DebugScreenshotsServices
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        services = AutopilotTestFixtures.services(center)
        context = AutopilotTestFixtures.context(services)
    }

    private var run: AutopilotRun? { center.run(for: appID) }

    /// Localize and check in English only, the set saved as v5, no extras.
    private static var localizing: AutopilotRun {
        var run = StudioDebugRuns.run(.localize)
        run.plan.localeCodes = ["en-US"]
        run.plan.alsoMakes = AutopilotExtras()
        run.templateVersion = 5
        run.overflows = []
        run.artworkTextNeeds = nil
        return run
    }

    @Test func whatEachStoppedRunResumes() {
        var run = Self.localizing
        #expect(AutopilotCenter.resume(for: run, isBusy: false) == .localize)
        #expect(AutopilotCenter.resume(for: run, isBusy: true) == nil, "Something on this Mac works on it")
        run.overflows = [AutopilotOverflow(locale: "th", slot: 0, displayType: .iPhone, headline: "", maxLines: 2, fill: 0)]
        #expect(AutopilotCenter.resume(for: run, isBusy: false) == nil, "The assistant's turn")
        run.overflows = []
        run.artworkTextNeeds = [AutopilotArtworkTextNeed(locale: "de-DE", role: .search, problem: .missing)]
        #expect(AutopilotCenter.resume(for: run, isBusy: false) == nil, "The assistant's turn")
        run.artworkTextNeeds = nil
        run.templateVersion = nil
        #expect(AutopilotCenter.resume(for: run, isBusy: false) == .chooseAgain)
        run.plan.runChoice.makesScreenshots = false
        #expect(AutopilotCenter.resume(for: run, isBusy: false) == .localize, "Without screenshots nothing is saved first")

        var watching = StudioDebugRuns.run(.watchPreview)
        watching.previewReview = AutopilotPreviewReview()
        #expect(AutopilotCenter.resume(for: watching, isBusy: false) == nil, "The person watches")
        watching.previewReview?.remake = AutopilotPreviewRemake(reason: .music("Calm piano"), total: 2)
        #expect(AutopilotCenter.resume(for: watching, isBusy: false) == .remix)
        watching.previewReview?.remake = AutopilotPreviewRemake(reason: .revision(2), total: 2)
        #expect(AutopilotCenter.resume(for: watching, isBusy: false) == .reviseAgain)

        for stage in [AutopilotStage.plan, .waiting, .capture, .pick, .design, .choose, .ready] {
            #expect(AutopilotCenter.resume(for: StudioDebugRuns.run(stage), isBusy: false) == nil, "\(stage)")
        }
    }

    @Test func aStoppedLocalizeGetsReady() async throws {
        center.install(Self.localizing)
        #expect(center.resumeInterruptedWork(appID, context: context))
        #expect(!center.resumeInterruptedWork(appID, context: context), "Once")
        for _ in 0..<500 where run?.stage == .localize {
            try await Task.sleep(for: .milliseconds(10))
        }
        let run = try #require(run)
        #expect(run.stage == .ready)
        #expect(run.log.map(\.text).contains("AppLocalizer closed while it was making them; picking up where it stopped"))
        #expect(center.localizing[appID, default: 0] == 0)
    }

    @Test func closingBeforeTheSetWasSavedGoesBackToTheChoice() throws {
        var start = Self.localizing
        start.templateVersion = nil
        center.install(start)
        #expect(center.resumeInterruptedWork(appID, context: context))
        let run = try #require(run)
        #expect(run.stage == .choose)
        #expect(run.chosenDirectionID == nil)
        #expect(run.directions == start.directions)
        #expect(run.log.last?.text == "AppLocalizer closed before the set was saved; choose the direction again")
    }

    @Test func aRevisionsAppPreviewGoesBackToTheDesignSource() throws {
        var start = StudioDebugRuns.run(.watchPreview)
        var review = AutopilotPreviewReview()
        review.request = AutopilotRevisionRequest(note: "Shorter", askedAt: AutopilotTestFixtures.now)
        review.remake = AutopilotPreviewRemake(reason: .revision(2), total: 2)
        start.previewReview = review
        center.install(start)
        #expect(center.resumeInterruptedWork(appID, context: context))
        let run = try #require(run)
        #expect(run.previewReview?.remake == nil)
        #expect(run.previewReview?.request?.note == "Shorter", "The note waits for the design source again")
    }

    /// Alba's run: its last retry ended with every capture in, in an
    /// AppLocalizer relaunched with no Claude Code to ask what's next. It
    /// moves on by itself instead of sitting at "224 of 224".
    @Test func aCaptureStageWithEveryCaptureInMovesOn() async throws {
        var start = AutopilotTestFixtures.run(.capture)
        #expect(AutopilotCenter.resume(for: start, isBusy: false) == nil, "Captures are left: the assistant's turn")
        AutopilotTestFixtures.captureAll(&start)
        #expect(AutopilotCenter.resume(for: start, isBusy: false) == .advance)
        center.install(start)
        #expect(center.resumeInterruptedWork(AutopilotTestFixtures.appID, context: context))
        for _ in 0..<500 where center.run(for: AutopilotTestFixtures.appID)?.stage == .capture {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(center.run(for: AutopilotTestFixtures.appID)?.stage != .capture)
    }

    @Test func aHeldRunDoesntResume() {
        let center = AutopilotTestFixtures.center(holdsStages: true)
        center.install(Self.localizing)
        #expect(!center.resumeInterruptedWork(appID, context: context))
        #expect(center.run(for: appID)?.stage == .localize)
    }
}
#endif
