//
//  AppPreviewCutterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// How the App Preview picks each screen's moment from the recording.
@Suite("App Preview cutter")
struct AppPreviewCutterTests {
    private let spec = AppPreviewSpec(displayType: .iPhone, pixelSize: PixelSize(width: 886, height: 1920))

    private func isClose(_ value: Double, _ expected: Double) -> Bool {
        abs(value - expected) < 0.000_1
    }

    private func marks(_ pairs: [(String, Double)]) -> [AutopilotRecordingMark] {
        pairs.map { AutopilotRecordingMark(screenID: $0.0, seconds: $0.1) }
    }

    @Test func screensShareTheLengthEqually() {
        let ids = ["a", "b", "c", "d", "e"]
        let marks = marks(zip(ids, [0, 8, 16, 24, 32]).map { ($0, $1) })
        let segments = AppPreviewCutter.segments(marks: marks, recordingSeconds: 40, screenIDs: ids, spec: spec)
        #expect(segments.map(\.screenID) == ids)
        #expect(segments.allSatisfy { isClose($0.duration, 4.2) })
        #expect(zip(segments, [0.3, 8.3, 16.3, 24.3, 32.3]).allSatisfy { isClose($0.start, $1) })
        let total = segments.map(\.duration).reduce(0, +)
        #expect(isClose(total + AppPreviewCutter.standardEndCardSeconds, spec.targetSeconds))
    }

    @Test func aShortMomentHandsItsShareOn() {
        let segments = AppPreviewCutter.segments(
            marks: marks([("a", 0), ("b", 2), ("c", 4)]), recordingSeconds: 60, screenIDs: ["a", "b", "c"], spec: spec
        )
        #expect(segments.count == 3)
        #expect(isClose(segments[0].duration, 1.6))
        #expect(isClose(segments[1].duration, 1.6))
        #expect(isClose(segments[2].duration, 17.8))
        let total = segments.map(\.duration).reduce(0, +)
        #expect(isClose(total + 3, 24))
    }

    @Test func aShortRecordingLengthensTheEndCard() {
        let segments = AppPreviewCutter.segments(
            marks: marks([("a", 0), ("b", 3), ("c", 6)]), recordingSeconds: 9, screenIDs: ["a", "b", "c"], spec: spec
        )
        #expect(segments.map(\.duration).count == 3)
        let total = segments.map(\.duration).reduce(0, +)
        #expect(isClose(total, 7.9))
        let endCard = AppPreviewCutter.endCardSeconds(forSegmentsTotal: total, spec: spec)
        #expect(isClose(endCard, 7.1))
        #expect(isClose(total + endCard, spec.minimumSeconds))
    }

    @Test func theEndCardIsThreeSecondsWhenTheScreensFillThePreview() {
        #expect(isClose(AppPreviewCutter.endCardSeconds(forSegmentsTotal: 21, spec: spec), 3))
        #expect(isClose(AppPreviewCutter.endCardSeconds(forSegmentsTotal: 26, spec: spec), 3))
    }

    @Test func tooManyScreensAreLeftOutFromTheEnd() {
        let ids = (0..<14).map { "s\($0)" }
        let marks = marks(ids.enumerated().map { ($1, Double($0) * 3) })
        let segments = AppPreviewCutter.segments(marks: marks, recordingSeconds: 42, screenIDs: ids, spec: spec)
        #expect(segments.map(\.screenID) == Array(ids.prefix(13)))
        #expect(segments.allSatisfy { isClose($0.duration, AppPreviewCutter.minimumScreenSeconds) })
        let total = segments.map(\.duration).reduce(0, +)
        #expect(total + AppPreviewCutter.endCardSeconds(forSegmentsTotal: total, spec: spec) <= spec.maximumSeconds)
    }

    @Test func screensPlayInThePlansOrderAndEndAtTheNextMarkInTime() {
        let marks = marks([("b", 1), ("a", 10), ("c", 5)])
        let segments = AppPreviewCutter.segments(marks: marks, recordingSeconds: 20, screenIDs: ["a", "b", "c", "d"], spec: spec)
        #expect(segments.map(\.screenID) == ["a", "b", "c"])
        #expect(isClose(segments[0].start, 10.3))
        #expect(isClose(segments[0].duration, 9.7))
        #expect(isClose(segments[1].start, 1.3))
        #expect(isClose(segments[1].duration, 3.6))
        #expect(isClose(segments[2].start, 5.3))
        #expect(isClose(segments[2].duration, 4.6))
    }

    @Test func marksOutsideTheRecordingAndRepeatsAreIgnored() {
        let marks = marks([("a", 2), ("a", 6), ("b", 50), ("c", -1)])
        let segments = AppPreviewCutter.segments(marks: marks, recordingSeconds: 12, screenIDs: ["a", "b", "c"], spec: spec)
        #expect(segments.map(\.screenID) == ["a"])
        #expect(isClose(segments[0].start, 2.3))
        #expect(isClose(segments[0].duration, 3.6))
    }

    @Test func noUsableMarkCutsNothing() {
        let segments = AppPreviewCutter.segments(marks: marks([("x", 1)]), recordingSeconds: 10, screenIDs: ["a"], spec: spec)
        #expect(segments.isEmpty)
        let late = AppPreviewCutter.segments(marks: marks([("a", 9.95)]), recordingSeconds: 10, screenIDs: ["a"], spec: spec)
        #expect(late.isEmpty)
    }

    @Test func lengthsAreWholeFrames() {
        let segments = AppPreviewCutter.segments(
            marks: marks([("a", 0), ("b", 1.234), ("c", 7.77)]), recordingSeconds: 13.01, screenIDs: ["a", "b", "c"], spec: spec
        )
        for segment in segments {
            let frames = segment.duration * Double(spec.framesPerSecond)
            #expect(abs(frames - frames.rounded()) < 0.000_1)
        }
        let total = segments.map(\.duration).reduce(0, +)
        let endFrames = AppPreviewCutter.endCardSeconds(forSegmentsTotal: total, spec: spec) * Double(spec.framesPerSecond)
        #expect(abs(endFrames - endFrames.rounded()) < 0.000_1)
    }
}
