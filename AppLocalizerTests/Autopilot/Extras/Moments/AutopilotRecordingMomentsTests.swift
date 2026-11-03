//
//  AutopilotRecordingMomentsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pick's App Preview recording (board 31): the moments Claude Code
/// marked, which go in (6 s each plus a 6 s end card, within Apple's
/// 15–30 s), and Record Again before the design step.
@MainActor
@Suite("Recording moments")
struct AutopilotRecordingMomentsTests {
    /// Pick with screenshots and an App Preview, its recordings marked
    /// with board 31's five moments, the first three suggested.
    private static var run: AutopilotRun { StudioDebugPick.picking() }

    private static func ids(_ run: AutopilotRun, _ slots: [Int]) -> [String] {
        slots.map { run.plan.screens[$0].id }
    }

    @Test func claudeCodesSuggestionsGoInFirst() {
        let run = Self.run
        #expect(run.hasRecordingMoments)
        #expect(run.pickableMoments.count == 5)
        #expect(run.pickableMoments.map(\.reason).first == "The prompt card fills in; calm, no typing")
        #expect(run.suggestedMomentIDs == Self.ids(run, [0, 1, 2]))
        #expect(run.chosenMomentIDs == run.suggestedMomentIDs)
        #expect(!run.changedMoments)
        #expect(run.pickedPreviewSeconds == 24)
        #expect(run.pickedPreviewLengthTitle == "0:24")
        #expect(run.pickedPreviewFits)
    }

    /// Six seconds a moment and the end card: one is too short, five too
    /// long, and Use These Picks waits outside 15–30 s.
    @Test(arguments: [(1, 12, false), (2, 18, true), (3, 24, true), (4, 30, true), (5, 36, false)])
    func theLengthFollowsTheChosenMoments(count: Int, seconds: Int, fits: Bool) {
        var run = Self.run
        for (index, moment) in run.pickableMoments.enumerated() {
            run.setMoment(moment.screenID, chosen: index < count)
        }
        #expect(run.chosenMomentIDs.count == count)
        #expect(run.pickedPreviewSeconds == seconds)
        #expect(run.pickedPreviewFits == fits)
        #expect(AutopilotRecordingMoment.previewSeconds == 6)
    }

    @Test func choosingKeepsThePlansOrder() {
        var run = Self.run
        run.setMoment(run.plan.screens[4].id, chosen: true)
        run.setMoment(run.plan.screens[0].id, chosen: false)
        #expect(run.chosenMomentIDs == Self.ids(run, [1, 2, 4]))
        #expect(run.changedMoments)
        run.setMoment(run.plan.screens[0].id, chosen: true)
        run.setMoment(run.plan.screens[4].id, chosen: false)
        #expect(!run.changedMoments, "Back to the suggestion")
    }

    /// Without Claude Code's suggestion, the first three it didn't advise
    /// against.
    @Test func withoutASuggestionTheFirstThreeGoIn() {
        var run = Self.run
        for (index, var recording) in (run.recordings ?? []).enumerated() {
            recording.markedMoments = recording.markedMoments?.enumerated().map { slot, moment in
                var moment = moment
                moment.suggested = slot == 1 ? false : nil
                return moment
            }
            run.recordings?[index] = recording
        }
        #expect(run.suggestedMomentIDs == Self.ids(run, [0, 2, 3]))
    }

    /// Only when each screen shows up: from once it settles to just
    /// before the next.
    @Test func marksMakeMomentsWhenClaudeCodeMarkedNone() {
        let marks = [
            AutopilotRecordingMark(screenID: "b", seconds: 5),
            AutopilotRecordingMark(screenID: "a", seconds: 1),
            AutopilotRecordingMark(screenID: "c", seconds: 40),
        ]
        let moments = AutopilotRecordingMoment.marked(marks, recordingSeconds: 12, screenIDs: ["a", "b", "c"])
        #expect(moments.map(\.screenID) == ["a", "b"], "A mark past the end makes no moment")
        #expect(moments[0].start == 1 + AppPreviewCutter.settleSeconds)
        #expect(moments[0].end == 5 - AppPreviewCutter.leadOutSeconds)
        #expect(moments[1].end == 12)
    }

    @Test func markedMomentsKeepThePlansOrderAndTheRecording() {
        let recording = AutopilotRecording(
            id: "rec", target: AutopilotRecordingTarget(displayType: .iPhone, locale: "en-US"), fileID: "file", pixelSize: PixelSize(width: 10, height: 20),
            seconds: 10, marks: [], receivedAt: AutopilotTestFixtures.now,
            markedMoments: [
                AutopilotRecordingMoment(screenID: "b", start: 6, end: 14, reason: "runs past the end"),
                AutopilotRecordingMoment(screenID: "a", start: 1, end: 5, reason: ""),
                AutopilotRecordingMoment(screenID: "x", start: 1, end: 5, reason: "not in the plan"),
                AutopilotRecordingMoment(screenID: "c", start: 11, end: 12, reason: "starts after it"),
            ]
        )
        let moments = recording.moments(screenIDs: ["a", "b", "c"])
        #expect(moments.map(\.screenID) == ["a", "b"])
        #expect(moments[1].end == 10)
    }

    @Test func theAppPreviewPlaysTheChosenMoments() throws {
        var run = Self.run
        run.setMoment(run.plan.screens[3].id, chosen: true)
        let recording = try #require(run.recordings?.first)
        let clips = try #require(run.previewClips(for: recording) { URL(filePath: "/tmp/\($0)") })
        #expect(clips.map(\.screenID) == Self.ids(run, [0, 1, 2, 3]))
        #expect(clips.first?.start == 2 && clips.first?.end == 8)
        #expect(clips.allSatisfy { $0.source == nil })
    }

    // MARK: - Record again

    @Test func recordAgainWaitsForATakeOnEveryRecording() throws {
        var run = Self.run
        let week = run.plan.screens[1].id
        run.askToRecordAgain(week)
        #expect(run.waitsForRetakes)
        let targets = run.pickRecordingTargets
        #expect(!targets.isEmpty)
        #expect(run.retakeTargets.map(\.screenID) == Array(repeating: week, count: targets.count))

        let first = try #require(targets.first)
        run.addRetake(Self.take(of: week, on: first))
        #expect(!run.isWaitingForRetake(week, on: first))
        #expect(run.waitsForRetakes == (targets.count > 1))
        for target in targets.dropFirst() { run.addRetake(Self.take(of: week, on: target)) }
        #expect(!run.waitsForRetakes)

        // The take plays in its place, from its own file.
        let recording = try #require(run.recording(for: first))
        let clips = try #require(run.previewClips(for: recording) { URL(filePath: "/tmp/\($0)") })
        let clip = try #require(clips.first { $0.screenID == week })
        #expect(clip.source == URL(filePath: "/tmp/take-\(first.locale)"))
        #expect(clip.start == 1 && clip.end == 7)
    }

    @Test func askingAgainDropsTheEarlierTake() throws {
        var run = Self.run
        let week = run.plan.screens[1].id
        run.askToRecordAgain(week)
        let target = try #require(run.pickRecordingTargets.first)
        run.addRetake(Self.take(of: week, on: target))
        #expect(run.retake(of: week, for: target) != nil)
        run.askToRecordAgain(week)
        #expect(run.retake(of: week, for: target) == nil)
        #expect(run.isWaitingForRetake(week, on: target))
    }

    @Test func theCenterAsksClaudeCodeBeforeTheDesign() async {
        let center = AutopilotTestFixtures.center()
        var run = Self.run
        run.appID = AutopilotTestFixtures.appID
        center.install(run)
        let week = run.plan.screens[1].id
        center.setMoment(appID: run.appID, screenID: week, chosen: false)
        #expect(center.run(for: run.appID)?.chosenMomentIDs == Self.ids(run, [0, 2]))
        center.askToRecordAgain(appID: run.appID, screenID: week)
        let asked = center.run(for: run.appID)
        #expect(asked?.momentRetakes == [week])
        #expect(asked?.log.last?.text == "Asked to record “Week” again before the design step")
        center.update(run.appID) { $0.stage = .design }
        let step = await center.nextStep(appID: run.appID, client: AutopilotTestFixtures.client)
        #expect(step == .recordAgain(screenIDs: [week]))
        // Past Pick, which moments go in stays as it was.
        center.setMoment(appID: run.appID, screenID: week, chosen: true)
        #expect(center.run(for: run.appID)?.chosenMomentIDs == Self.ids(run, [0, 2]))
    }

    private static func take(of screenID: String, on target: AutopilotRecordingTarget) -> AutopilotRecording {
        AutopilotRecording(
            id: "take-\(target.displayType.mcpValue)-\(target.locale)", target: target, fileID: "take-\(target.locale)",
            pixelSize: target.displayType.portraitPixelSize, seconds: 8, marks: [AutopilotRecordingMark(screenID: screenID, seconds: 1)],
            receivedAt: AutopilotTestFixtures.now,
            markedMoments: [AutopilotRecordingMoment(screenID: screenID, start: 1, end: 7, reason: "", suggested: true)], retakeOf: screenID
        )
    }
}
#endif
