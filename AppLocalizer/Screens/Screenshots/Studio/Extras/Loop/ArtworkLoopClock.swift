//
//  ArtworkLoopClock.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Where a header or search loop is as it plays in the viewer: playing or
/// paused, its place in the 20 seconds, moved by a skip or the scrubber.
/// AppLocalizer's own artwork draws each frame at `position(at:)`; a
/// Claude Design page follows `playback`, and waits for its page to load
/// (`waitForPage`, `pageReady`) so the two keep time.
@MainActor
@Observable
final class ArtworkLoopClock {
    /// What a page follows: it seeks to `seconds` and plays or pauses
    /// whenever `change` moves.
    struct Playback: Equatable {
        var isPlaying: Bool
        var seconds: Double
        var change: Int
    }

    static var length: Double { Double(AutopilotArtworkMotion.loopSeconds) }

    private(set) var isPlaying = true
    /// Where it was when it last started, paused or moved, in seconds.
    private(set) var anchor: Double = 0
    /// When it last started from `anchor`.
    private(set) var startedAt = Date.now
    /// False while a page loads: the loop waits at `anchor` meanwhile.
    private(set) var isReady = true
    private(set) var change = 0
    @ObservationIgnored private var resumesAfterScrub = false
    /// What "now" is, for tests.
    @ObservationIgnored var now: () -> Date = { .now }

    var playback: Playback { Playback(isPlaying: isPlaying && isReady, seconds: anchor, change: change) }

    /// Seconds into the loop at `date`: running, or where it waits.
    func position(at date: Date) -> Double {
        guard isPlaying, isReady else { return anchor }
        return Self.wrap(anchor + date.timeIntervalSince(startedAt))
    }

    var seconds: Double { position(at: now()) }

    /// From the start, playing: a loop that just showed. A page's loop
    /// waits until its page is loaded.
    func restart(waitsForPage: Bool = false) {
        anchor = 0
        startedAt = now()
        isPlaying = true
        isReady = !waitsForPage
        resumesAfterScrub = false
        change += 1
    }

    /// The page is waiting to load again (its captures arrived).
    func waitForPage() {
        guard isReady else { return }
        anchor = seconds
        isReady = false
        change += 1
    }

    /// The page loaded: the loop runs from where it waited, and the page
    /// is told to seek there.
    func pageReady() {
        guard !isReady else { return }
        startedAt = now()
        isReady = true
        change += 1
    }

    func toggle() {
        if isPlaying { pause() } else { play() }
    }

    func play() {
        guard !isPlaying else { return }
        startedAt = now()
        isPlaying = true
        change += 1
    }

    func pause() {
        guard isPlaying else { return }
        anchor = seconds
        isPlaying = false
        change += 1
    }

    /// To `seconds` into the loop, within it; playing on if it was.
    func seek(to seconds: Double) {
        anchor = min(max(0, seconds), Self.length - 1.0 / 30)
        startedAt = now()
        change += 1
    }

    /// A drag on the scrubber pauses the loop until it ends.
    func scrub(_ active: Bool) {
        if active {
            resumesAfterScrub = isPlaying
            pause()
        } else if resumesAfterScrub {
            resumesAfterScrub = false
            play()
        }
    }

    /// "0:07 / 0:20".
    func timeTitle(at date: Date) -> String {
        "\(AutopilotRun.timeTitle(position(at: date).rounded(.down))) / \(AutopilotRun.timeTitle(Self.length))"
    }

    /// `elapsed` seconds wrapped into the 20-second loop.
    static func wrap(_ elapsed: Double) -> Double {
        let wrapped = elapsed.truncatingRemainder(dividingBy: length)
        return wrapped < 0 ? wrapped + length : wrapped
    }
}
