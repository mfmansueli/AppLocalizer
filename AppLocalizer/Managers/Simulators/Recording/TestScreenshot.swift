//
//  TestScreenshot.swift
//  AppLocalizer
//

import Foundation

/// A screenshot a UI test attached, as its result bundle records it
/// (`XcresultTimeline`): the test, the name it gave it, when it was
/// attached, and since when the test was at that screen: the step before
/// it started then, e.g. waiting for the sheet's label.
struct TestScreenshot: Hashable, Sendable {
    /// e.g. `ScreenshotUITests/testStreak()`.
    var test: String
    /// e.g. `streak`.
    var name: String
    /// Seconds since 1970.
    var time: Double
    var readySince: Double?
    /// The simulator the test ran on.
    var deviceID: String?
}
