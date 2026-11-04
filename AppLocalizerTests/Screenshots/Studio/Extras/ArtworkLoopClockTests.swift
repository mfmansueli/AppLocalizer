//
//  ArtworkLoopClockTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A loop playing full size goes round its 20 seconds: it plays, pauses,
/// skips and scrubs, and a page's loop waits for its page.
@MainActor
@Suite("ArtworkLoopClock")
struct ArtworkLoopClockTests {
    /// The clock's "now", moved by hand.
    private final class Time {
        var now = Date(timeIntervalSinceReferenceDate: 1000)
    }

    private func clock(_ time: Time) -> ArtworkLoopClock {
        let clock = ArtworkLoopClock()
        clock.now = { time.now }
        clock.restart()
        return clock
    }

    private func isAbout(_ value: Double, _ expected: Double) -> Bool { abs(value - expected) < 0.0001 }

    @Test(arguments: [
        (0.0, 0.0),
        (7.5, 7.5),
        (20, 0),
        (47, 7),
        (-3, 17),
    ])
    func timeWrapsIntoTheLoop(elapsed: Double, position: Double) {
        #expect(isAbout(ArtworkLoopClock.wrap(elapsed), position))
    }

    @Test func theLoopIsTwentySeconds() {
        #expect(ArtworkScene.loopSeconds == 20)
        #expect(ArtworkLoopClock.length == ArtworkScene.loopSeconds)
    }

    @Test func itPlaysPausesAndGoesOnFromWhereItWas() {
        let time = Time()
        let clock = clock(time)
        time.now += 3
        #expect(isAbout(clock.seconds, 3))
        clock.pause()
        time.now += 5
        #expect(isAbout(clock.seconds, 3))
        #expect(clock.playback == .init(isPlaying: false, seconds: 3, change: clock.change))
        clock.play()
        time.now += 2
        #expect(isAbout(clock.seconds, 5))
        time.now += 20
        #expect(isAbout(clock.seconds, 5), "Round again")
        clock.toggle()
        #expect(!clock.isPlaying)
    }

    @Test func skippingAndScrubbingStayInTheLoop() {
        let time = Time()
        let clock = clock(time)
        let before = clock.change
        clock.seek(to: 12)
        #expect(clock.change == before + 1, "A page seeks with it")
        #expect(clock.playback.seconds == 12)
        time.now += 1
        #expect(isAbout(clock.seconds, 13), "Playing on from there")
        clock.seek(to: -4)
        #expect(clock.seconds == 0)
        clock.seek(to: 25)
        #expect(isAbout(clock.seconds, 20 - 1.0 / 30), "The last frame, not round to the first")
    }

    @Test func aDragPausesUntilItEnds() {
        let time = Time()
        let clock = clock(time)
        clock.scrub(true)
        #expect(!clock.isPlaying)
        clock.seek(to: 8)
        time.now += 3
        #expect(isAbout(clock.seconds, 8))
        clock.scrub(false)
        #expect(clock.isPlaying, "It was playing")
        time.now += 1
        #expect(isAbout(clock.seconds, 9))

        clock.pause()
        clock.scrub(true)
        clock.seek(to: 2)
        clock.scrub(false)
        #expect(!clock.isPlaying, "It was paused, and stays so")
    }

    @Test func aPagesLoopWaitsForItsPage() {
        let time = Time()
        let clock = clock(time)
        clock.restart(waitsForPage: true)
        time.now += 4
        #expect(clock.seconds == 0, "Nothing plays while the page loads")
        #expect(!clock.playback.isPlaying)
        clock.pageReady()
        #expect(clock.playback.isPlaying)
        time.now += 2
        #expect(isAbout(clock.seconds, 2))

        // The captures arrive and the page loads again.
        clock.waitForPage()
        time.now += 3
        #expect(isAbout(clock.seconds, 2))
        clock.pageReady()
        #expect(clock.playback == .init(isPlaying: true, seconds: 2, change: clock.change), "The new page seeks to where it was")
        clock.pageReady()
        #expect(clock.playback.seconds == 2, "Once")
    }

    @Test func itSaysWhereItIs() {
        let time = Time()
        let clock = clock(time)
        time.now += 7.6
        #expect(clock.timeTitle(at: time.now) == "0:07 / 0:20")
    }
}
