//
//  AppPreviewSoundtrackTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The App Preview's sound track: the music looped to the App Preview's
/// length, faded in and out, under the captions' level.
@Suite("App Preview music · sound track")
struct AppPreviewSoundtrackTests {
    private static let rate = AppPreviewSynth.sampleRate

    /// `seconds` of a constant `value` on both sides.
    private func flat(_ value: Float, seconds: Double) -> [Float] {
        [Float](repeating: value, count: Int(seconds * Self.rate) * 2)
    }

    private func level(_ soundtrack: AppPreviewSoundtrack, at seconds: Double) -> Float {
        let frame = Int(seconds * Self.rate)
        return Float(soundtrack.samples[frame * 2]) / Float(Int16.max)
    }

    @Test func itIsAsLongAsTheAppPreview() {
        let soundtrack = AppPreviewSoundtrack(stereo: flat(0.5, seconds: 1), seconds: 6)
        #expect(soundtrack.frameCount == Int(6 * Self.rate))
        #expect(abs(soundtrack.seconds - 6) < 0.000_1)
    }

    @Test func shorterMusicLoops() {
        // 1 s of rising ramp: the sound track repeats it every second.
        let frames = Int(Self.rate)
        var ramp: [Float] = []
        for frame in 0..<frames {
            let value = Float(frame) / Float(frames)
            ramp += [value, value]
        }
        let soundtrack = AppPreviewSoundtrack(stereo: ramp, seconds: 5)
        #expect(level(soundtrack, at: 1.5) == level(soundtrack, at: 2.5))
        #expect(level(soundtrack, at: 1.5) > level(soundtrack, at: 1.2))
    }

    @Test func itFadesInAndOutAroundTheLevel() {
        let soundtrack = AppPreviewSoundtrack(stereo: flat(1, seconds: 10), seconds: 10)
        #expect(level(soundtrack, at: 0) == 0)
        #expect(level(soundtrack, at: AppPreviewSoundtrack.fadeInSeconds / 2) < AppPreviewSoundtrack.level)
        #expect(abs(level(soundtrack, at: 5) - AppPreviewSoundtrack.level) < 0.001, "Under the captions at full level")
        #expect(level(soundtrack, at: 9) < level(soundtrack, at: 8.5), "Fading out over the last two seconds")
        #expect(abs(level(soundtrack, at: 8.5) - AppPreviewSoundtrack.level * 0.75) < 0.01)
        #expect(soundtrack.samples.suffix(2) == [0, 0], "Silent on the last frame")
    }

    @Test func nothingToPlayIsSilence() {
        let soundtrack = AppPreviewSoundtrack(stereo: [], seconds: 2)
        #expect(soundtrack.frameCount == Int(2 * Self.rate))
        #expect(soundtrack.samples.allSatisfy { $0 == 0 })
    }

    @Test func copyingPastTheEndIsSilence() {
        let soundtrack = AppPreviewSoundtrack(stereo: flat(1, seconds: 1), seconds: 1)
        var buffer = [Int16](repeating: 7, count: 8)
        buffer.withUnsafeMutableBytes { bytes in
            soundtrack.copy(frames: 4, from: Int64(soundtrack.frameCount - 2), into: bytes.baseAddress!)
        }
        #expect(Array(buffer.suffix(4)) == [0, 0, 0, 0])
        #expect(buffer.prefix(4).allSatisfy { $0 != 7 })
    }

    @Test func aLibraryTrackIsMadeOnThisMac() async throws {
        let soundtrack = try await AppPreviewSoundtrack.make(.track(.brightPop), seconds: 3)
        #expect(soundtrack.frameCount == Int(3 * Self.rate))
        #expect(soundtrack.samples.contains { abs(Int($0)) > 1000 })
    }

    @Test func theOwnFileWithoutAFileIsMissing() async {
        await #expect(throws: AppPreviewError.noMusicFile) {
            try await AppPreviewSoundtrack.make(.track(.ownFile), seconds: 3)
        }
    }
}
