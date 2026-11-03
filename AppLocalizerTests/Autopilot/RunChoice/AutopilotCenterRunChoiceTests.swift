//
//  AutopilotCenterRunChoiceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What "What this run makes" changes in a run: the last captures reused
/// or captured again, Capture and Pick skipped, and a run without
/// screenshots that leaves the set as it is.
@MainActor
@Suite("Autopilot center · run choice")
struct AutopilotCenterRunChoiceTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    private var run: AutopilotRun? { center.run(for: appID) }

    /// A finished run of the small plan with every capture and its picks.
    private var finishedRun: AutopilotRun {
        var run = AutopilotTestFixtures.run(.ready)
        AutopilotTestFixtures.captureAll(&run)
        run.pickBest()
        return run
    }

    /// The last capture's day, as the plan shows it: "Oct 28".
    private var keptDay: String {
        AutopilotTestFixtures.now.addingTimeInterval(7).formatted(.dateTime.month(.abbreviated).day())
    }

    /// A new plan after `finishedRun`, reusing its captures or not.
    private func prepareAfterFinishedRun(reusing: Bool) {
        center.install(finishedRun)
        center.prepare(appID: appID, versionString: "1.5", plan: AutopilotTestFixtures.smallPlan)
        center.updatePlan(for: appID) { $0.runChoice.reusesCaptures = reusing }
    }

    @Test func aNewPlanRemembersTheCapturesAndPicksItCouldReuse() throws {
        prepareAfterFinishedRun(reusing: false)
        let run = try #require(run)
        let kept = try #require(run.keptFrom)
        #expect(kept.versionString == "1.4")
        #expect(kept.capturedAt == AutopilotTestFixtures.now.addingTimeInterval(7))
        #expect(kept.displayTypes == [.iPhone, .iPad])
        #expect(kept.localeCount == 2)
        #expect(kept.hasPicks)
        #expect(run.picks == finishedRun.picks)
        #expect(run.keptDate == keptDay)
    }

    @Test func aFirstPlanHasNothingToReuse() {
        center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)
        #expect(run?.keptFrom == nil)
        #expect(run?.keptDate == nil)
    }

    @Test func startingCapturesAgainUnlessTheRunReusesTheLastCaptures() {
        prepareAfterFinishedRun(reusing: false)
        center.start(appID: appID)
        #expect(run?.captures.isEmpty == true)
        #expect(run?.picks.isEmpty == true)
        #expect(run?.keptCaptureCount == 0)
        #expect(run?.remainingTargets.count == 8)
        #expect(run?.captureSkipNote == nil)
        #expect(run?.pickSkipNote == nil)
    }

    @Test func reusingSkipsCaptureAndPick() {
        prepareAfterFinishedRun(reusing: true)
        center.start(appID: appID)
        #expect(run?.captures.count == 8)
        #expect(run?.remainingTargets.isEmpty == true)
        #expect(run?.skipsCapture == true)
        #expect(run?.skipsPick == true)
        #expect(run?.captureSkipNote == "Skipped · reuses the \(keptDay) captures")
        #expect(run?.pickSkipNote == "Skipped · uses the \(keptDay) picks")
    }

    @Test func aNewScreenIsCapturedEvenWhenReusing() {
        prepareAfterFinishedRun(reusing: true)
        center.updatePlan(for: appID) { $0.appendScreen(AutopilotScreen(name: "Insights", steps: "tab “Insights”", origin: .person), on: .iPhone) }
        center.start(appID: appID)
        #expect(run?.remainingTargets.map(\.screenID) == Array(repeating: "insights", count: 4))
        #expect(run?.skipsCapture == false)
        #expect(run?.captureSkipNote == nil)
    }

    @Test func aStoppedRunKeepsItsOwnCaptures() {
        var started = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&started, except: [AutopilotTestFixtures.target("week", .iPad, "de-DE")])
        center.install(started)
        center.stop(appID: appID)
        center.start(appID: appID)
        #expect(run?.captures.count == 7, "Captured in this run, not reused")
    }

    @Test func withNothingLeftToCaptureTheRunGoesStraightToTheDesign() async throws {
        prepareAfterFinishedRun(reusing: true)
        center.start(appID: appID)
        let services = AutopilotTestFixtures.services(center)
        await center.skipCapturingIfDone(appID, context: AutopilotTestFixtures.context(services))

        let run = try #require(run)
        #expect(run.stage == .choose, "AppLocalizer's starters, then the person chooses")
        #expect(run.directions.count == AutopilotRun.directionCount)
        #expect(run.picks.count == 2)
        #expect(run.log.map(\.text).contains("Skipped capturing: reuses the \(keptDay) captures and picks"))
    }

    @Test func aRunThatStillCapturesIsntSkipped() async {
        prepareAfterFinishedRun(reusing: false)
        center.start(appID: appID)
        let services = AutopilotTestFixtures.services(center)
        await center.skipCapturingIfDone(appID, context: AutopilotTestFixtures.context(services))
        #expect(run?.stage == .waiting)
    }

    // MARK: - Without screenshots

    @Test func headerAndSearchWithoutScreenshotsLeavesTheSetAsItIs() async throws {
        let center = AutopilotTestFixtures.center()
        let services = AutopilotTestFixtures.services(center)
        let context = AutopilotTestFixtures.context(services)
        let before = try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        var start = StudioDebugRuns.run(.choose)
        start.plan.localeCodes = ["en-US", "de-DE"]
        start.plan.runChoice.makesScreenshots = false
        start.plan.alsoMakes.makesArtwork = true
        center.install(start)
        await center.useDirection("d-1", appID: StudioDebugRuns.appID, context: context)

        let run = try #require(center.run(for: StudioDebugRuns.appID))
        #expect(run.templateVersion == nil, "No new template version")
        #expect(run.overflows.isEmpty, "The set's captions aren't checked")
        let after = try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(after.history?.currentNumber == before.history?.currentNumber)
        #expect(after.template == before.template)
        #expect(after.captions == before.captions)
        #expect(after.captures == before.captures)
        if run.stage == .localize {
            // The artwork's texts first, like captions.
            #expect(run.artworkTextNeeds?.isEmpty == false)
        } else {
            #expect(run.stage == .ready)
            #expect(run.log.last?.text == "Ready in Review & Push: header and search artwork; the live screenshots stay as they are")
            #expect(after.extras?.artwork.isEmpty == false)
        }
    }

    @Test func artworkMadeAloneKeepsTheAppPreviewsMadeBefore() async throws {
        let center = AutopilotTestFixtures.center()
        let services = AutopilotTestFixtures.services(center)
        let context = AutopilotTestFixtures.context(services)
        var document = try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        let earlier = ExtrasPreviewFile(
            displayType: .iPhone, locale: "en-US", recordedLocale: "en-US", fileID: "mov-1", seconds: 24,
            pixelSize: PixelSize(width: 886, height: 1920), byteCount: 4_000_000, posterSeconds: 5
        )
        document.extras = ScreenshotExtras(directionName: "Quiet Indigo", madeAt: AutopilotTestFixtures.now, previews: [earlier])
        document.extras?.discardedChecksums = ["iphone-en-US": "mov-1"]
        try await services.saveDocument(document, for: AutopilotTestFixtures.app)

        var start = StudioDebugRuns.run(.localize)
        start.plan.localeCodes = ["en-US"]
        start.plan.runChoice.makesScreenshots = false
        start.plan.alsoMakes.makesArtwork = true
        center.install(start)
        await center.makeExtras(StudioDebugRuns.appID, context: context)

        let extras = try #require(try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS).extras)
        #expect(extras.previews == [earlier])
        #expect(extras.discardedChecksums == ["iphone-en-US": "mov-1"], "Discarded in review, it stays out")
    }

    // MARK: - Texts

    @Test func theEstimateAndPromptOfARunWithoutScreenshots() {
        var plan = StudioDebugRuns.plan
        plan.localeCodes = ["en-US", "de-DE"]
        plan.runChoice.makesScreenshots = false
        plan.alsoMakes.makesArtwork = true
        #expect(AutopilotEstimate.summary(for: plan, design: .none, kept: plan.targets.count)
            == "Header and search artwork in 2 languages · nothing to capture on this Mac; about 2 min of design")
        #expect(AutopilotEstimate.summary(for: plan, design: .none).hasPrefix("Header and search artwork in 2 languages · about 1 min on this Mac"))

        let prompt = AutopilotPrompt.start(appName: "Lumen Journal", appID: StudioDebugRuns.appID, plan: plan)
        #expect(prompt.contains("it makes header and search artwork, and no screenshots"))
        #expect(prompt.contains("Build the app, capture the screens the header and search artwork show, and send them back."))
        #expect(prompt.contains("get_capture_plan"))

        plan.alsoMakes.makesArtwork = false
        plan.alsoMakes.makesAppPreview = true
        let preview = AutopilotPrompt.start(appName: "Lumen Journal", appID: StudioDebugRuns.appID, plan: plan)
        #expect(preview.contains("Record the App Preview walkthrough"))
        #expect(!preview.contains("capture the screens"))
    }
}
#endif
