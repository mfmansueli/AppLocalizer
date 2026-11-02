//
//  DisplayRecordingTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The helper's `record-display` lines read into a recording: its folder,
/// each frame's times, a capture that matched the frame before, and the
/// oldest frame dropped.
@Suite("Display recording")
struct DisplayRecordingTests {
    @Test func readsTheFolderAndEachFrame() {
        var recording = DisplayRecording()
        RecordingTestFixtures.recordingLines.forEach { recording.read($0) }
        #expect(recording.folder == RecordingTestFixtures.folder)
        #expect(recording.frames == RecordingTestFixtures.frames)
        let last = RecordingTestFixtures.frames[3]
        #expect(recording.path(of: last) == RecordingTestFixtures.folder + "/" + last.file)
    }

    @Test func aMatchingCaptureKeepsTheFrameLonger() {
        var recording = DisplayRecording()
        recording.read("same 1793626241.000")
        #expect(recording.frames.isEmpty, "Nothing to match yet")
        recording.read("frame 1793626240.200 1793626240.800 frame-a.png")
        recording.read("same 1793626241.400")
        #expect(recording.frames.first?.lastSeen == 1_793_626_241.4)
        #expect(recording.frames.first?.end == 1_793_626_240.8)
    }

    @Test func aDroppedFrameGoesAndOtherLinesAreIgnored() {
        var recording = DisplayRecording()
        for line in [
            "frame 1 2 frame-a.png", "frame 3 4 frame-b.png", "dropped frame-a.png", "frame x 4 frame-c.png", "frame 5 6",
            "applocalizer-helper-exit 0", "",
        ] {
            recording.read(line)
        }
        #expect(recording.frames.map(\.file) == ["frame-b.png"])
        #expect(recording.folder == nil)
        #expect(recording.path(of: recording.frames[0]) == nil)
    }
}
#endif
