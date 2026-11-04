//
//  PlayerScrubberTests.swift
//  AppLocalizerTests
//

import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The scrubber shows how far along a video is and turns a click or drag
/// into a moment in it.
@MainActor
@Suite("PlayerScrubber")
struct PlayerScrubberTests {
    @Test func itFillsAsFarAsTheVideoHasPlayed() {
        #expect(PlayerScrubber.fraction(5, of: 20) == 0.25)
        #expect(PlayerScrubber.fraction(30, of: 20) == 1)
        #expect(PlayerScrubber.fraction(-1, of: 20) == 0)
        #expect(PlayerScrubber.fraction(3, of: 0) == 0, "No length yet")
    }

    @Test func aClickIsTheMomentUnderIt() {
        #expect(PlayerScrubber.seconds(at: 75, width: 100, duration: 20) == 15)
        #expect(PlayerScrubber.seconds(at: -10, width: 100, duration: 20) == 0)
        #expect(PlayerScrubber.seconds(at: 140, width: 100, duration: 20) == 20)
        #expect(PlayerScrubber.seconds(at: 10, width: 0, duration: 20) == 20, "A bar with no width doesn't divide by zero")
    }

    @Test func itSaysTheTimeInMinutesAndSeconds() {
        #expect(PlayerScrubber.title(7.9) == "0:07")
        #expect(PlayerScrubber.title(65) == "1:05")
        #expect(PlayerScrubber.title(-2) == "0:00")
        #expect(PlayerScrubber.step == 5)
    }
}
