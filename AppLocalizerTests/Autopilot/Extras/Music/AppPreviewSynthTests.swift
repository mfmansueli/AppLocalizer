//
//  AppPreviewSynthTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// AppLocalizer's music library, synthesized on this Mac: as long as
/// asked, stereo, never clipping, never silent, the same every time.
@Suite("App Preview music · library")
struct AppPreviewSynthTests {
    @Test(arguments: AppPreviewTrack.library)
    func aTrackIsAsLongAsAskedInStereo(track: AppPreviewTrack) {
        let samples = AppPreviewSynth.render(track, seconds: 2.5)
        #expect(samples.count == Int(2.5 * AppPreviewSynth.sampleRate) * 2)
    }

    @Test(arguments: AppPreviewTrack.library)
    func aTrackPlaysJustUnderFullScale(track: AppPreviewTrack) throws {
        let samples = AppPreviewSynth.render(track, seconds: 4)
        let peak = try #require(samples.map(abs).max())
        #expect(abs(peak - 0.95) < 0.001, "Peaks at 0.95, got \(peak)")
        let loud = samples.count { abs($0) > 0.05 }
        #expect(loud > samples.count / 20, "Music all the way through, not a click: \(loud) of \(samples.count)")
    }

    @Test(arguments: AppPreviewTrack.library)
    func aTrackSoundsTheSameEveryTime(track: AppPreviewTrack) {
        #expect(AppPreviewSynth.render(track, seconds: 3) == AppPreviewSynth.render(track, seconds: 3))
    }

    @Test func bothSidesPlay() {
        let samples = AppPreviewSynth.render(.warmAcoustic, seconds: 3)
        let left = stride(from: 0, to: samples.count, by: 2).map { samples[$0] }
        let right = stride(from: 1, to: samples.count, by: 2).map { samples[$0] }
        #expect(left.contains { abs($0) > 0.1 })
        #expect(right.contains { abs($0) > 0.1 })
        #expect(left != right, "The instruments are panned")
    }

    @Test func theTracksSoundDifferent() {
        let tracks = AppPreviewTrack.library.map { AppPreviewSynth.render($0, seconds: 2) }
        for (index, track) in tracks.enumerated() {
            for other in tracks[(index + 1)...] { #expect(track != other) }
        }
    }

    @Test func theLibraryIsTheFeaturedTracksAndTheRest() {
        #expect(AppPreviewTrack.library == AppPreviewTrack.featured + AppPreviewTrack.more)
        #expect(Set(AppPreviewTrack.library).count == 7)
        #expect(!AppPreviewTrack.library.contains(.ownFile))
    }

    @Test func theOwnFileIsntSynthesized() {
        #expect(AppPreviewSynth.render(.ownFile, seconds: 2).isEmpty)
        #expect(AppPreviewSynth.render(.calmPiano, seconds: 0).isEmpty)
    }
}
