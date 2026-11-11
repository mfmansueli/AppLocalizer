//
//  ScreenshotsPageHeaderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("ScreenshotsPageHeader")
struct ScreenshotsPageHeaderTests {
    @Test func theButtonStartsAutopilotUntilARunIsUnderWay() {
        #expect(ScreenshotsPageHeader.autopilotTitle(stage: nil) == "Start Autopilot…")
        #expect(ScreenshotsPageHeader.autopilotTitle(stage: .plan) == "Start Autopilot…")
    }

    @Test(arguments: [AutopilotStage.waiting, .capture, .pick, .design, .choose, .localize, .watchPreview, .ready])
    func theButtonOpensTheRunUnderWay(stage: AutopilotStage) {
        #expect(ScreenshotsPageHeader.autopilotTitle(stage: stage) == "Open Autopilot…")
    }

    /// Starting a run is Pro's; a run under way opens as it is.
    @Test func onlyStartingARunIsGated() {
        #expect(ScreenshotsPageHeader.startsRun(stage: nil))
        #expect(ScreenshotsPageHeader.startsRun(stage: .plan))
        #expect(!ScreenshotsPageHeader.startsRun(stage: .capture))
        #expect(!ScreenshotsPageHeader.startsRun(stage: .ready))
    }
}
