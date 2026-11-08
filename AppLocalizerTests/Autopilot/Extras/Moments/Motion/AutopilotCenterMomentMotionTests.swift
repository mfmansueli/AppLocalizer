//
//  AutopilotCenterMomentMotionTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A moment that barely moves goes back to the assistant once, through
/// Record Again; a second take that's still still stays, for Review to say.
@MainActor
@Suite("App Preview moments · asking again for motion")
struct AutopilotCenterMomentMotionTests {
    private static let still = AutopilotMomentMotion(movingShare: 0, stillSeconds: 6)
    private static let moving = AutopilotMomentMotion(movingShare: 0.6, stillSeconds: 0.5)
    private static let file = URL(filePath: "/tmp/preview.mov")

    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    private var run: AutopilotRun? { center.run(for: appID) }

    /// Pick with five marked moments, the first three suggested.
    private func installed() throws -> (run: AutopilotRun, recording: AutopilotRecording) {
        var run = StudioDebugPick.picking()
        run.appID = appID
        center.install(run)
        let target = try #require(run.pickRecordingTargets.first)
        return try (run, #require(run.recording(for: target)))
    }

    private func read(_ motion: AutopilotMomentMotion?) {
        center.readMotion = { _, _, _ in motion }
    }

    private static func take(of screenID: String, on target: AutopilotRecordingTarget) -> AutopilotRecording {
        AutopilotRecording(
            id: "take-\(target.locale)", target: target, fileID: "take-\(target.locale)", pixelSize: target.displayType.portraitPixelSize, seconds: 8,
            marks: [AutopilotRecordingMark(screenID: screenID, seconds: 1)], receivedAt: AutopilotTestFixtures.now,
            markedMoments: [AutopilotRecordingMoment(screenID: screenID, start: 1, end: 7, reason: "", suggested: true)], retakeOf: screenID
        )
    }

    @Test func whatBarelyMovesIsAskedForAgain() async throws {
        let (run, recording) = try installed()
        read(Self.still)
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        let asked = try #require(self.run)
        #expect(asked.motionRetakes == run.suggestedMomentIDs)
        #expect(asked.momentRetakes == run.suggestedMomentIDs)
        #expect(asked.momentsWaitingForMotion == run.suggestedMomentIDs)
        #expect(asked.log.last?.text.contains("Almost nothing moves in") == true)
        center.update(appID) { $0.stage = .design }
        #expect(await center.nextStep(appID: appID, client: AutopilotTestFixtures.client) == .recordAgain(screenIDs: run.suggestedMomentIDs))
    }

    @Test func whatMovesIsLeftAlone() async throws {
        let (run, recording) = try installed()
        read(Self.moving)
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        let measured = try #require(self.run)
        #expect(Set(measured.momentMotion?.keys.map(\.self) ?? []) == Set(run.suggestedMomentIDs))
        #expect(measured.motionRetakes == nil)
        #expect(measured.momentRetakes == nil)
    }

    /// The fourth and fifth moments are marked use: false.
    @Test func whatTheAssistantLeftOutIsntMeasured() async throws {
        let (run, recording) = try installed()
        read(Self.still)
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        for slot in [3, 4] {
            #expect(self.run?.momentMotion?[run.plan.screens[slot].id] == nil)
        }
    }

    @Test func aScreenIsAskedForOnlyOnce() async throws {
        let (run, recording) = try installed()
        read(Self.still)
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        let week = run.plan.screens[1].id
        center.update(appID) { run in
            for target in run.pickRecordingTargets { run.addRetake(Self.take(of: week, on: target)) }
        }
        let lines = self.run?.log.count
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        let again = try #require(self.run)
        #expect(again.motionRetakes == run.suggestedMomentIDs)
        #expect(again.log.count == lines)
        for target in run.pickRecordingTargets {
            #expect(again.retake(of: week, for: target) != nil, "The take stays")
        }
        #expect(!again.momentsWaitingForMotion.contains(week))
    }

    @Test func onlyTheRecordingTheAppPreviewUsesIsMeasured() async throws {
        let (_, recording) = try installed()
        read(Self.still)
        let other = AutopilotRecording(
            id: "other", target: AutopilotRecordingTarget(displayType: .iPad, locale: "de-DE"), fileID: recording.fileID, pixelSize: recording.pixelSize,
            seconds: recording.seconds, marks: [], receivedAt: AutopilotTestFixtures.now, markedMoments: recording.markedMoments
        )
        await center.measureMotion(of: other, file: Self.file, appID: appID)
        #expect(run?.momentMotion == nil)
        #expect(run?.motionRetakes == nil)
    }

    @Test func aFileThatCantBeReadAsksForNothing() async throws {
        let (_, recording) = try installed()
        read(nil)
        await center.measureMotion(of: recording, file: Self.file, appID: appID)
        #expect(run?.momentMotion == nil)
        #expect(run?.momentRetakes == nil)
    }

    /// A take is measured for Review, and never sent back a third time.
    @Test func aStillTakeStaysAndReviewNamesIt() async throws {
        let (run, _) = try installed()
        let week = run.plan.screens[1].id
        let target = try #require(run.pickRecordingTargets.first)
        read(Self.still)
        await center.measureRetake(Self.take(of: week, on: target), file: Self.file, appID: appID)
        var measured = try #require(self.run)
        #expect(measured.momentMotion?[week] == Self.still)
        #expect(measured.motionRetakes == nil)
        #expect(measured.tooStillMomentNames == ["Week"])
        measured.setMoment(week, chosen: false)
        #expect(measured.tooStillMomentNames.isEmpty, "Only what goes in")
    }

    @Test func aMovingTakeClearsTheWarning() async throws {
        let (run, _) = try installed()
        let week = run.plan.screens[1].id
        let target = try #require(run.pickRecordingTargets.first)
        center.update(appID) { $0.noteMotion([week: Self.still]) }
        read(Self.moving)
        await center.measureRetake(Self.take(of: week, on: target), file: Self.file, appID: appID)
        #expect(self.run?.tooStillMomentNames.isEmpty == true)
    }
}
#endif
