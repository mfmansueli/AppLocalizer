//
//  AppPreviewSoundtrack.swift
//  AppLocalizer
//

import Foundation

/// The App Preview's sound track, as long as the App Preview: the music
/// (looped when it's shorter), faded in briefly, faded out over the last
/// two seconds, at the level it plays under the captions, as 16-bit stereo
/// at 44.1 kHz. `AppPreviewWriter` writes it beside the video.
struct AppPreviewSoundtrack: Sendable {
    static let fadeInSeconds = 0.3
    static let fadeOutSeconds = 2.0
    /// The music's peak level: about −4 dB, under the captions.
    static let level: Float = 0.62

    /// Interleaved left, right.
    let samples: [Int16]

    var frameCount: Int { samples.count / 2 }
    var seconds: Double { Double(frameCount) / AppPreviewSynth.sampleRate }

    /// The music from `source`, `seconds` long.
    static func make(_ source: AppPreviewMusicSource, seconds: Double) async throws -> AppPreviewSoundtrack {
        switch source {
        case let .track(track):
            guard track.isLibrary else { throw AppPreviewError.noMusicFile }
            return AppPreviewSoundtrack(stereo: AppPreviewSynth.render(track, seconds: seconds), seconds: seconds)
        case let .file(url):
            return try await AppPreviewSoundtrack(stereo: AppPreviewMusicFile.samples(of: url), seconds: seconds)
        }
    }

    /// `stereo` (interleaved, −1…1) looped or cut to `seconds`, faded and
    /// leveled.
    init(stereo: [Float], seconds: Double) {
        let frames = max(0, Int((seconds * AppPreviewSynth.sampleRate).rounded()))
        let sourceFrames = stereo.count / 2
        guard sourceFrames > 0 else {
            samples = [Int16](repeating: 0, count: frames * 2)
            return
        }
        let fadeIn = Int(Self.fadeInSeconds * AppPreviewSynth.sampleRate)
        let fadeOut = min(frames, Int(Self.fadeOutSeconds * AppPreviewSynth.sampleRate))
        var out = [Int16](repeating: 0, count: frames * 2)
        for frame in 0..<frames {
            let from = frame % sourceFrames
            var gain = Self.level
            if frame < fadeIn { gain *= Float(frame) / Float(max(fadeIn, 1)) }
            let left = frames - frame
            if left <= fadeOut { gain *= Float(left - 1) / Float(max(fadeOut, 1)) }
            for channel in 0..<2 {
                let value = min(max(stereo[from * 2 + channel] * gain, -1), 1)
                out[frame * 2 + channel] = Int16(value * Float(Int16.max))
            }
        }
        samples = out
    }

    /// Writes `count` frames starting at frame `start` into `destination`
    /// (4 bytes a frame), silence past the end.
    func copy(frames count: Int, from start: Int64, into destination: UnsafeMutableRawPointer) {
        let target = destination.bindMemory(to: Int16.self, capacity: count * 2)
        samples.withUnsafeBufferPointer { source in
            for index in 0..<(count * 2) {
                let sample = Int(start) * 2 + index
                target[index] = sample < source.count ? source[sample] : 0
            }
        }
    }
}
