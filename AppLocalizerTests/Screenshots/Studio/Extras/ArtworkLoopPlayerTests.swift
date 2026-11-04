//
//  ArtworkLoopPlayerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A loop playing full size goes round its 20 seconds.
@MainActor
@Suite("ArtworkLoopPlayer")
struct ArtworkLoopPlayerTests {
    @Test(arguments: [
        (0.0, 0.0),
        (7.5, 7.5),
        (20, 0),
        (47, 7),
        (-3, 17),
    ])
    func timeWrapsIntoTheLoop(elapsed: Double, position: Double) {
        #expect(abs(ArtworkLoopPlayer.position(elapsed: elapsed) - position) < 0.0001)
    }

    @Test func theLoopIsTwentySeconds() {
        #expect(ArtworkScene.loopSeconds == 20)
        #expect(Double(AutopilotArtworkMotion.loopSeconds) == ArtworkScene.loopSeconds)
    }
}
