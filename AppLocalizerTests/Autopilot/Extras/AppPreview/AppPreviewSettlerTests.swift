//
//  AppPreviewSettlerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// MB Admin's App Preview opened on an empty list still loading: a moment
/// now starts once its screen has filled in.
@MainActor
@Suite("App Preview settler")
struct AppPreviewSettlerTests {
    private static let spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 886, height: 1920))

    @Test func itStartsOnceTheScreenHasFilledIn() {
        #expect(AppPreviewSettler.offset(blankShares: [0.5, 0.45, 0.1, 0.08, 0.1]) == 0.5)
        #expect(AppPreviewSettler.offset(blankShares: [0.6, nil, 0.2]) == 0.5)
    }

    /// Bruma's Match moment: the Home Screen (other apps' icons), the
    /// white launch screen, the screen fading in, then the match.
    @Test func aRelaunchAtTheStartIsSkipped() {
        #expect(AppPreviewSettler.offset(blankShares: [0.1, 0.95, 0.6, 0.05, 0.05, 0.06]) == 0.75)
        #expect(AppPreviewSettler.offset(blankShares: [0.1, 0.9, 0.05, 0.4, 0.05]) == 1, "After the last blank frame")
        #expect(AppPreviewSettler.offset(blankShares: [0.1, 0.1, 0.95, 0.95]) == 0, "Turns blank and stays: a photo vanishing once seen")
    }

    /// Bruma's recording, a frame every 0.25 s from 0.25 s before the Match
    /// moment's relaunch (measured): Activity, the Home Screen, the white
    /// launch screen, the match fading in at 2.5 s. The Home Screen was
    /// the emptiest frame, and the look stopped at 2.5 s: it was kept.
    @Test func brumasMatchStartsOnTheMatch() {
        let match: [Double?] = [0.07, 0.02, 0.02, 0.88, 0.98, 0.98, 0.98, 0.98, 0.98, 1.00, 0.10, 0.11, 0.10, 0.07, 0.07, 0.07, 0.08]
        #expect(AppPreviewSettler.offset(blankShares: match) == 2.5)
        #expect(AppPreviewSettler.offset(blankShares: Array(match.prefix(11))) == 2.5, "As far as it used to look")
    }

    /// A screen turning blank later on, then filling in, is the moment's
    /// own: only a launch or a load in its first seconds is skipped.
    @Test func aBlankLaterInTheMomentIsItsOwn() {
        let late: [Double?] = Array(repeating: 0.05, count: 13) + [0.95, 0.95, 0.05, 0.05]
        #expect(AppPreviewSettler.offset(blankShares: late) == 0)
    }

    @Test func itLooksUpToSixSecondsLeavingASecond() {
        #expect(AppPreviewSettler.span(of: 5) == 4)
        #expect(AppPreviewSettler.span(of: 3) == 2)
        #expect(AppPreviewSettler.span(of: 20) == 6)
        #expect(AppPreviewSettler.span(of: 1.5) == 0.75)
    }

    @Test func aScreenThatOpensFilledInOrCantBeReadStays() {
        #expect(AppPreviewSettler.offset(blankShares: [0.1, 0.1, 0.05]) == 0, "Less than 0.15 blanker")
        #expect(AppPreviewSettler.offset(blankShares: [nil, 0.1]) == 0)
        #expect(AppPreviewSettler.offset(blankShares: []) == 0)
        #expect(AppPreviewSettler.offset(blankShares: [1, 1, 1]) == 0, "A flat screen throughout")
    }

    @Test func itKeepsItsLengthWhenTheMomentHasRoom() {
        let segment = AppPreviewSegment(screenID: "today", start: 1, duration: 6)
        let roomy = AppPreviewSettler.moved(segment, by: 0.5, momentEnd: 10, spec: Self.spec)
        #expect(roomy.start == 1.5)
        #expect(roomy.duration == 6)

        let tight = AppPreviewSettler.moved(segment, by: 0.5, momentEnd: 7.2, spec: Self.spec)
        #expect(tight.start == 1.5)
        #expect(abs(tight.duration - 5.7) < 0.0001, "It ends with its moment")
        #expect(AppPreviewSettler.moved(segment, by: 0.5, momentEnd: nil, spec: Self.spec).end == 7, "Or where it did")
        #expect(AppPreviewSettler.moved(segment, by: 0.5, momentEnd: 6.5, spec: Self.spec).end == 7)
    }

    /// Bruma's iPad Match lost 2.4 s to its relaunch and the end card took
    /// them, running 8.4 s of 24: the other moments get them back while
    /// they have room.
    @Test func whatASegmentLostGoesToTheOthers() {
        let segments = [
            AppPreviewSegment(screenID: "nearby", start: 0, duration: 3),
            AppPreviewSegment(screenID: "chat", start: 10, duration: 3),
            AppPreviewSegment(screenID: "match", start: 22.4, duration: 1.2),
        ]
        let ends = ["nearby": 4.5, "chat": 13.5, "match": 23.6]
        let refilled = AppPreviewSettler.refilled(segments, lost: 2, momentEnds: ends, spec: Self.spec)
        let durations = refilled.map(\.duration)
        #expect(abs(durations[0] - 4.5) < 0.0001, "\(durations)")
        #expect(abs(durations[1] - 3.5) < 0.0001, "Up to its moment's end: \(durations)")
        #expect(durations[2] == 1.2, "No room left in its own moment")
        #expect(refilled.map(\.start) == segments.map(\.start))

        let crowded = AppPreviewSettler.refilled(segments, lost: 9, momentEnds: ends, spec: Self.spec)
        #expect(abs(crowded.map(\.duration).reduce(0, +) - 9.2) < 0.0001, "As much as the moments hold; the end card takes the rest")
        #expect(AppPreviewSettler.refilled(segments, lost: 0, momentEnds: ends, spec: Self.spec) == segments)
    }

    /// A second of a blank screen, then a busy one, at 10 frames a second.
    private nonisolated static func writeLoadingRecording(to url: URL) async throws {
        var spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 240, height: 520))
        spec.framesPerSecond = 10
        let writer = try AppPreviewWriter(output: url, spec: spec, bitRate: 2_000_000)
        for index in 0..<40 {
            let isBusy = Double(index) / 10 >= 1
            try await writer.appendFrame { context in
                context.setFillColor(CGColor(gray: 1, alpha: 1))
                context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
                guard isBusy else { return }
                context.setFillColor(CGColor(gray: 0, alpha: 1))
                for y in stride(from: 0, to: context.height, by: 8) {
                    for x in stride(from: (y / 8).isMultiple(of: 2) ? 0 : 4, to: context.width, by: 8) {
                        context.fill(CGRect(x: x, y: y, width: 4, height: 4))
                    }
                }
            }
        }
        try await writer.finish()
    }

    @Test func aLoadingOpeningIsSkippedInARecording() async throws {
        let url = AppPreviewTestRecording.temporaryURL("loading.mov")
        defer { try? FileManager.default.removeItem(at: url) }
        try await Self.writeLoadingRecording(to: url)

        let segment = AppPreviewSegment(screenID: "today", start: 0.3, duration: 3)
        let settled = await AppPreviewSettler.settled([segment], recording: url, momentEnds: ["today": 3.9], spec: Self.spec)
        #expect(settled.count == 1)
        // 0.75 s in, rounded up to whole frames at 30 fps; not room for
        // all of it after that, so it ends with its moment.
        let start = try #require(settled.first?.start)
        #expect(abs(start - (0.3 + 23.0 / 30)) < 0.001, "\(settled)")
        #expect(abs((settled.first?.end ?? 0) - 3.9) < 0.04, "\(settled)")
    }
}
#endif
