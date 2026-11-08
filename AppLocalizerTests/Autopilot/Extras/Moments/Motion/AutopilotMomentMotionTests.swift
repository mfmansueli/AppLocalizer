//
//  AutopilotMomentMotionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What counts as moving, against the real numbers of the Bruma recording
/// that looked like a slideshow.
@Suite("App Preview moments · how much they move")
struct AutopilotMomentMotionTests {
    private static func zeros(_ count: Int) -> [Double] {
        [Double](repeating: 0, count: count)
    }

    /// Each moment of Bruma's recording, every 0.25 s.
    static let nearby = [Double](repeating: 0.001, count: 24)
    static let profile = [0.009, 0.006] + zeros(22)
    static let chat = [0.000, 0.917, 0.006, 0.006, 0.012, 0.001, 0.261, 0.088, 0.002] + zeros(15)
    static let activity = [0.969, 0.548, 0.011] + zeros(5) + [0.975, 0.020] + zeros(14)

    @Test(arguments: [nearby, profile, chat, activity])
    func brumasMomentsAreTooStill(changes: [Double]) {
        #expect(AutopilotMomentMotion(changes: changes).isTooStill)
    }

    @Test func aScreenInUseIsntTooStill() {
        let changes: [Double] = (0..<6).flatMap { _ -> [Double] in [0.05, 0.02, 0, 0] }
        let motion = AutopilotMomentMotion(changes: changes)
        #expect(motion.movingShare == 0.5)
        #expect(motion.stillSeconds == 0.5)
        #expect(!motion.isTooStill)
    }

    /// A relaunch flashes nearly every pixel: that isn't the app moving.
    @Test func aCutIsntMotion() {
        let motion = AutopilotMomentMotion(changes: [0, 0, 0.95, 0, 0])
        #expect(motion.movingShare == 0)
        #expect(motion.stillSeconds == 0.5, "The cut ends the still stretch")
    }

    @Test func nothingButCutsMovesNothing() {
        #expect(AutopilotMomentMotion(changes: [0.9, 0.95]).movingShare == 0)
    }

    @Test func aLongPauseIsTooStillEvenInABusyMoment() {
        let changes = [Double](repeating: 0.05, count: 16) + Self.zeros(16)
        let motion = AutopilotMomentMotion(changes: changes)
        #expect(motion.movingShare == 0.5)
        #expect(motion.stillSeconds == 4)
        #expect(motion.isTooStill)
    }

    @Test func aBlinkingCursorStaysBelowMoving() {
        let motion = AutopilotMomentMotion(changes: [Double](repeating: AutopilotMomentMotion.movedShare, count: 24))
        #expect(motion.movingShare == 0)
    }
}
