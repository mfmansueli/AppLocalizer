//
//  ScreenshotStudioPickTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pick the best captures (board 31): each screen's pick with its
/// attempts, whose pick it is, iPhone Duo's displays, the recording's
/// moments, and the footer that says what Use These Picks uses, which
/// waits while the App Preview is outside Apple's 15–30 s.
@MainActor
@Suite("ScreenshotStudioModel · Pick")
struct ScreenshotStudioPickTests {
    private static func model(_ run: AutopilotRun) async -> ScreenshotsViewModel {
        await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(run))
    }

    @Test func screenshotsAndTheRecordingEachHaveATab() async throws {
        let model = await Self.model(StudioDebugPick.picking())
        let run = try #require(model.studio.run)
        #expect(model.studio.pickTabs(run) == [.screenshots, .recording])
        #expect(model.studio.currentPickTab(run) == .screenshots)
        #expect(model.studio.pickDevices(run) == [.phones])
        #expect(model.studio.pickNote(run, device: .phones).contains("Click any capture to see it full size"))

        // Only an App Preview: only the recording.
        var previewOnly = StudioDebugRuns.run(.pick)
        AutopilotRunPreset.appPreview.apply(to: &previewOnly.plan, devices: [.iPhone, .iPad], canReuse: false)
        StudioDebugPickRecording.addRecordings(to: &previewOnly)
        let alone = await Self.model(previewOnly)
        let only = try #require(alone.studio.run)
        #expect(alone.studio.pickTabs(only) == [.recording])
        #expect(alone.studio.currentPickTab(only) == .recording)
    }

    @Test func choosingAnotherAttemptMakesItYourPick() async throws {
        let model = await Self.model(StudioDebugPick.picking())
        var run = try #require(model.studio.run)
        let week = run.plan.screens[1].id
        #expect(model.studio.pickBadge(run, screenID: week) == "Claude Code’s pick")
        #expect(model.studio.pickFooterText(run) == "Claude Code’s picks are selected · App Preview: 3 moments + end card, 0:24.")
        let attempts = model.studio.pickAttempts(run, screenID: week)
        #expect(attempts.first?.isUsed == true)
        #expect(attempts.filter(\.isUsed).count == 1)

        let second = try #require(run.candidates(for: week).dropFirst().first)
        run.picks[week] = second.id
        #expect(model.studio.isYourPick(run, screenID: week))
        #expect(model.studio.pickBadge(run, screenID: week) == "Your pick")
        #expect(model.studio.pickReason(run, screenID: week).hasPrefix("⚠︎ Ranked lower: "))
        #expect(model.studio.changedPickCount(run) == 1)
        #expect(model.studio.pickFooterText(run) == "1 pick changed by you; the rest are Claude Code’s · App Preview: 3 moments + end card, 0:24.")
        #expect(model.studio.pickAttempts(run, screenID: week).first { $0.isUsed }?.capture.id == second.id)
    }

    /// Use These Picks waits outside 15–30 s, and the summary says which
    /// way to go.
    @Test func useThesePicksWaitsOutsideFifteenToThirtySeconds() async throws {
        let model = await Self.model(StudioDebugPick.picking())
        let start = try #require(model.studio.run)
        #expect(model.studio.canUsePicks(start))
        #expect(model.studio.momentsSummary(start) == "App Preview: Today, Week, Search and the end card · 0:24 · within Apple’s 15–30 s")

        for moment in model.studio.pickMoments(start) { model.studio.setMoment(moment, chosen: true) }
        let long = try #require(model.studio.run)
        #expect(long.pickedPreviewSeconds == 36)
        #expect(!model.studio.canUsePicks(long))
        #expect(model.studio.momentsSummary(long).hasSuffix("· 0:36 · over Apple’s 30 s: remove a moment"))
        #expect(model.studio.pickFooterText(long).hasSuffix("App Preview: 5 moments + end card, 0:36."))

        for moment in model.studio.pickMoments(long).dropFirst() { model.studio.setMoment(moment, chosen: false) }
        let short = try #require(model.studio.run)
        #expect(!model.studio.canUsePicks(short))
        #expect(model.studio.momentsSummary(short).hasSuffix("· 0:12 · under Apple’s 15 s: add a moment"))
        #expect(model.studio.pickFooterText(short).hasSuffix("App Preview: 1 moment + end card, 0:12."))

        // Without a recording there's nothing to wait for.
        let screensOnly = await Self.model(StudioDebugRuns.run(.pick))
        let plain = try #require(screensOnly.studio.run)
        #expect(screensOnly.studio.canUsePicks(plain))
        #expect(screensOnly.studio.pickFooterText(plain) == "Claude Code’s picks are selected.")
    }

    @Test func theRecordingIsMomentsBetweenScreens() async throws {
        let model = await Self.model(StudioDebugPick.picking())
        let run = try #require(model.studio.run)
        #expect(model.studio.recordingTitle(run).hasPrefix("Raw recording · "))
        #expect(model.studio.recordingTitle(run).hasSuffix(" · 0:38"))
        let pieces = model.studio.recordingPieces(run)
        #expect(pieces.first?.kind == .between)
        #expect(pieces.last?.kind == .end)
        let today = try #require(pieces.first { $0.id == "moment.\(run.plan.screens[0].id)" })
        #expect(today.title == "Today · 0:02–0:08 · in the App Preview")
        let photos = try #require(pieces.first { $0.id == "moment.\(run.plan.screens[3].id)" })
        #expect(photos.kind == .moment(chosen: false))
        #expect(!photos.title.contains("in the App Preview"))
    }

    @Test func recordAgainSaysWhatHappensNext() async throws {
        let model = await Self.model(StudioDebugPick.picking())
        let run = try #require(model.studio.run)
        let week = try #require(model.studio.pickMoments(run).dropFirst().first)
        #expect(model.studio.recordAgainNote(run, moment: week) == nil)
        model.studio.recordAgain(week)
        let asked = try #require(model.studio.run)
        #expect(model.studio.recordAgainNote(asked, moment: week)
            == "Claude Code will record “Week” again before the design step. The rest of the recording stays.")
    }

    @Test func iPhoneDuoShowsTheDisplaysTheRowChose() async throws {
        let model = await Self.model(StudioDebugDuoStates.run(.pick, .both, .sideBySide))
        let run = try #require(model.studio.run)
        #expect(model.studio.pickDevices(run) == [.phones, .duo])
        #expect(model.studio.pickNote(run, device: .duo) == "Same moments as iPhone, on the inner and cover displays. Click to see them full size.")
        let both = model.studio.duoCaptures(run, screenID: run.plan.screens[0].id)
        #expect(both.inner != nil && both.cover != nil)
        #expect(both.cover.map { CaptureSizeRules.isDuoOuterDisplay($0.pixelSize) } == true)

        let inner = await Self.model(StudioDebugDuoStates.run(.pick, .inner, .sideBySide))
        let innerRun = try #require(inner.studio.run)
        #expect(inner.studio.pickNote(innerRun, device: .duo) == "Same moments as iPhone, on the inner display. Click to see them full size.")
        let alone = inner.studio.duoCaptures(innerRun, screenID: innerRun.plan.screens[0].id)
        #expect(alone.inner != nil && alone.cover == nil)
    }
}
#endif
