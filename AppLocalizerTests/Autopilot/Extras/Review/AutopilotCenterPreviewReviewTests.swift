//
//  AutopilotCenterPreviewReviewTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Watch the App Preview: Localize stops there when an App Preview was
/// made, the person approves it, changes its music (mixed again without a
/// design step) or asks Claude Design for changes, whose new version is
/// made again from the same recordings.
@MainActor
@Suite("Autopilot · watch the App Preview", .serialized)
struct AutopilotCenterPreviewReviewTests {
    private let center = AutopilotTestFixtures.center()
    private let services: DebugScreenshotsServices
    private let context: AutopilotContext
    private let appID = StudioDebugRuns.appID

    init() {
        services = AutopilotTestFixtures.services(center)
        context = AutopilotTestFixtures.context(services)
    }

    private var run: AutopilotRun? { center.run(for: appID) }
    private var review: AutopilotPreviewReview? { run?.previewReview }

    private func lumen(_ stage: AutopilotStage) -> AutopilotRun {
        AutopilotPreviewTestRun.run(stage)
    }

    /// Watching v1, with a small real recording and the set saved.
    private func watching(design: Bool = true) async throws -> AutopilotRun {
        try await AutopilotPreviewTestRun.watching(center: center, services: services, design: design)
    }

    private func savedDocument() async throws -> ScreenshotsDocument {
        try await services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
    }

    private func revise(
        cut: AppPreviewCut, look: ScreenshotTemplate? = nil, track: AppPreviewTrack? = nil, changes: String = "Slower pace, starts with Search"
    ) async throws {
        try await center.revisePreview(
            AutopilotPreviewDraft(cut: cut, changes: changes, look: look, track: track, client: AutopilotTestFixtures.client),
            appID: appID, context: context
        )
    }

    // MARK: - Finishing Localize

    @Test func localizeStopsToWatchTheAppPreview() throws {
        center.install(lumen(.localize))
        center.finishMaking(appID, extras: StudioDebugExtras.extras(for: lumen(.ready)), readyLine: "Ready")
        let run = try #require(run)
        #expect(run.stage == .watchPreview)
        #expect(run.previewReview?.version == 1)
        #expect(run.finishedAt == nil)
        #expect(run.log.last?.text == "App Preview v1 ready to watch")
    }

    @Test func withoutTheStopOrAnAppPreviewTheSetIsReady() throws {
        var skipping = lumen(.localize)
        skipping.plan.stopsToWatchPreview = false
        center.install(skipping)
        center.finishMaking(appID, extras: StudioDebugExtras.extras(for: lumen(.ready)), readyLine: "Ready")
        #expect(run?.stage == .ready)
        #expect(run?.previewReview == nil)

        center.install(lumen(.localize))
        var extras = try #require(StudioDebugExtras.extras(for: lumen(.ready)))
        extras.previews = []
        center.finishMaking(appID, extras: extras, readyLine: "Ready")
        #expect(run?.stage == .ready, "None could be made: nothing to watch")
        #expect(run?.finishedAt == AutopilotTestFixtures.now)
        #expect(run?.log.last?.text == "Ready")
    }

    @Test func aRunWithoutAnAppPreviewGoesStraightToReady() {
        var run = StudioDebugRuns.run(.localize)
        run.plan.alsoMakes = AutopilotExtras()
        center.install(run)
        center.finishMaking(appID, extras: nil, readyLine: "Ready")
        #expect(self.run?.stage == .ready)
    }

    // MARK: - Approve and ask

    @Test func approvingGoesOnToReviewAndPush() throws {
        center.install(lumen(.watchPreview))
        center.approvePreview(appID: appID)
        let run = try #require(run)
        #expect(run.stage == .ready)
        #expect(run.finishedAt == AutopilotTestFixtures.now)
        #expect(run.log.last?.text == "App Preview v1 approved · everything is in Review & Push")
    }

    @Test func askingHandsTheNoteToClaudeDesign() async throws {
        center.install(lumen(.watchPreview))
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .wait(
            reason: "The person is watching the App Preview.", seconds: 20
        ))

        center.requestPreviewChanges("  Slower pace, start with Search \n", appID: appID)
        let request = try #require(review?.request)
        #expect(request.note == "Slower pace, start with Search")
        #expect(run?.handedBackAt == AutopilotTestFixtures.now)
        #expect(run?.log.last?.text == "Asked Claude Design for App Preview changes: “Slower pace, start with Search”")
        let step = await center.nextStep(appID: appID, client: AutopilotTestFixtures.client)
        #expect(try step == .revisePreview(note: "Slower pace, start with Search", review: #require(review)))

        center.approvePreview(appID: appID)
        #expect(run?.stage == .watchPreview, "Approve waits for the new version")
        center.requestPreviewChanges("Faster", appID: appID)
        #expect(review?.request?.note == "Slower pace, start with Search", "One change at a time")
    }

    @Test func anEmptyNoteOrNoDesignSourceAsksNothing() {
        var watching = lumen(.watchPreview)
        center.install(watching)
        center.requestPreviewChanges("   ", appID: appID)
        #expect(review?.request == nil)

        watching.designKind = .none
        center.install(watching)
        center.requestPreviewChanges("Slower pace", appID: appID)
        #expect(review?.request == nil, "Classic without a design project: nobody makes a new version")
    }

    /// MB Admin's guided run had no design project, and its ask box said
    /// "Needs a design project": a guided plan has Claude Code take the
    /// asks, as it designs the header concepts.
    @Test func withoutADesignProjectAGuidedRunAsksClaude() async throws {
        var watching = lumen(.watchPreview)
        watching.designKind = .none
        watching.plan.assistantDesignsArtwork = true
        center.install(watching)
        #expect(run?.reviser == .claudeDesign)

        center.requestPreviewChanges("Slower pace", appID: appID)
        let review = try #require(review)
        #expect(review.request?.note == "Slower pace")
        #expect(run?.log.last?.text == "Asked Claude Design for App Preview changes: “Slower pace”")
        #expect(run?.assistantHasWork == true, "AppLocalizer starts Claude Code for it")
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .revisePreview(note: "Slower pace", review: review))

        watching.plan.assistantDesignsArtwork = nil
        #expect(watching.reviser == nil)
        watching.designKind = .claudeDesign
        #expect(watching.reviser == .claudeDesign)
    }

    // MARK: - Revisions

    @Test func aRevisionIsMadeAgainAsTheNextVersion() async throws {
        let before = try await watching()
        center.requestPreviewChanges("Slower pace, start with Search", appID: appID)
        let ids = before.plan.screens.map(\.id)
        let cut = AppPreviewCut(screenIDs: [ids[2], ids[0], ids[1]], seconds: 28)
        try await revise(cut: cut, track: .calmPiano)

        let review = try #require(review)
        #expect(review.version == 2)
        #expect(review.cut == cut)
        #expect(review.request == nil)
        #expect(review.remake == nil)
        #expect(review.revisions == [AutopilotPreviewRevision(
            version: 2, changes: "Slower pace, starts with Search", note: "Slower pace, start with Search", client: "Claude Code",
            madeAt: AutopilotTestFixtures.now
        )])
        #expect(run?.plan.alsoMakes.previewMusic.track == .calmPiano)
        #expect(run?.stage == .watchPreview, "The person watches v2 before approving it")
        #expect(run?.log.contains { $0.text == "Claude Code sent App Preview v2: Slower pace, starts with Search" } == true)

        let extras = try #require(try await savedDocument().extras)
        let preview = try #require(extras.previews.first)
        #expect(extras.previews.count == 1)
        #expect(!preview.fileID.hasPrefix("debug-preview"), "The new file replaced the earlier one")
        #expect(preview.scenes?.first?.screenID == ids[2], "It starts where the cut says")
        #expect(AppPreviewCut.secondsRange.contains(preview.seconds))
        #expect(extras.previewMusic?.track == .calmPiano)
        #expect(FileManager.default.fileExists(atPath: services.extrasFileURL(preview.fileID, pathExtension: "mov", for: AutopilotTestFixtures.app).path))
    }

    @Test func aRevisionIsRefusedWhenNothingWasAsked() async throws {
        _ = try await watching()
        await #expect(throws: AutopilotError.self) { try await revise(cut: AppPreviewCut(seconds: 20)) }
        #expect(review?.version == 1)
    }

    @Test func aRevisionNamesOnlyTheRunsScreensAndTheLibrarysTracks() async throws {
        _ = try await watching()
        center.requestPreviewChanges("Start with Search", appID: appID)
        do {
            try await revise(cut: AppPreviewCut(screenIDs: ["search-everything"]))
            Issue.record("An unknown screen must be refused")
        } catch {
            #expect(error.localizedDescription.hasPrefix("No screen “search-everything” in this run"))
        }
        await #expect(throws: AutopilotError.self) { try await revise(cut: AppPreviewCut(endCardScreenID: "elsewhere")) }
        do {
            try await revise(cut: AppPreviewCut(), track: .ownFile)
            Issue.record("The person's own file must be refused")
        } catch {
            #expect(error.localizedDescription.hasPrefix("Only the person can choose their own file"))
        }
        #expect(review?.request != nil, "The request waits for a revision that can be made")
        #expect(review?.version == 1)
    }

    @Test func aRevisionIsRefusedAwayFromWatching() async {
        center.install(lumen(.ready))
        await #expect(throws: AutopilotError.self) { try await revise(cut: AppPreviewCut()) }
    }

    // MARK: - Music

    @Test func theMusicAtThePlanIsThePlans() async {
        center.install(lumen(.plan))
        await center.setPreviewMusic(AutopilotPreviewMusic(track: .brightPop), appID: appID, context: context)
        #expect(run?.plan.alsoMakes.previewMusic.track == .brightPop)
    }

    @Test func otherMusicIsMixedAgainWithoutADesignStep() async throws {
        _ = try await watching(design: false)
        await center.setPreviewMusic(AutopilotPreviewMusic(track: .brightPop), appID: appID, context: context)
        #expect(run?.plan.alsoMakes.previewMusic.track == .brightPop)
        #expect(review?.version == 1, "Music isn't a new version")
        #expect(review?.remake == nil)
        #expect(run?.log.last?.text == "Mixed again with Bright pop · music doesn’t need a design step")
        let extras = try #require(try await savedDocument().extras)
        #expect(extras.previewMusic?.track == .brightPop)
        #expect(extras.previews.first?.fileID.hasPrefix("debug-preview") == false)
    }

    @Test func theSameMusicOrABusyReviewChangesNothing() async {
        var watching = lumen(.watchPreview)
        center.install(watching)
        await center.setPreviewMusic(.standard, appID: appID, context: context)
        #expect(run?.log == watching.log, "Warm acoustic is already playing")

        watching.previewReview?.request = AutopilotRevisionRequest(note: "Faster", askedAt: AutopilotTestFixtures.now)
        center.install(watching)
        await center.setPreviewMusic(AutopilotPreviewMusic(track: .calmPiano), appID: appID, context: context)
        #expect(run?.plan.alsoMakes.previewMusic == .standard, "Waits for Claude Design's version")
    }

    @Test func aRemakeSaysWhatItsDoing() {
        var remake = AutopilotPreviewRemake(reason: .music("Calm piano"), done: 1, total: 2)
        #expect(remake.title == "Mixing again with Calm piano · 1 of 2")
        remake = AutopilotPreviewRemake(reason: .revision(2), total: 1)
        #expect(remake.title == "Making App Preview v2")
        var plan = lumen(.plan).plan
        plan.alsoMakes.previewLanguages = .all
        plan.runChoice.previewDisplays = [.iPhone, .iPad]
        #expect(AutopilotCenter.previewCount(of: plan) == 2 * plan.localeCodes.count)
    }
}
#endif
