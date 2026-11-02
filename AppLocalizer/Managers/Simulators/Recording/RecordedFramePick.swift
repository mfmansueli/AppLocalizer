//
//  RecordedFramePick.swift
//  AppLocalizer
//

import Foundation

/// The frame of a recording kept for a screenshot a UI test took: the last
/// one whose capture ended before the test's own screenshot, so it shows
/// what the test saw then. A test waits for the screen (and often a moment
/// more) before its screenshot, and closes the app right after, so the
/// frame comes from that wait. Nil when the recording has none from before.
struct RecordedFramePick: Hashable, Sendable {
    var screenshot: TestScreenshot
    var frame: RecordedFrame?

    /// How long before the test's screenshot the frame's capture ended.
    var lead: Double? {
        frame.map { screenshot.time - $0.end }
    }

    /// The frame's capture started after the test's step before its
    /// screenshot did, so the screen was there. When it didn't (a test that
    /// takes its screenshot the moment the screen appears), it may show the
    /// screen before.
    var isSettled: Bool {
        guard let frame else { return false }
        guard let ready = screenshot.readySince else { return true }
        return frame.start >= ready
    }

    /// The frame for each screenshot.
    static func picks(for screenshots: [TestScreenshot], in frames: [RecordedFrame]) -> [RecordedFramePick] {
        let frames = frames.sorted { $0.end < $1.end }
        return screenshots.map { screenshot in
            RecordedFramePick(screenshot: screenshot, frame: frames.last { $0.end <= screenshot.time })
        }
    }
}
