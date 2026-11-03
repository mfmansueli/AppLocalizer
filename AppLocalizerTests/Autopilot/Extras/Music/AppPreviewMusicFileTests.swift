//
//  AppPreviewMusicFileTests.swift
//  AppLocalizerTests
//

import AVFoundation
import Foundation
import Testing
@testable import AppLocalizer

/// The person's own music file, read as the App Preview plays it: stereo
/// at 44.1 kHz, at most 40 seconds, and a plain error for a file that
/// isn't audio or has no sound.
@Suite("App Preview music · own file")
struct AppPreviewMusicFileTests {
    /// A WAV file of `seconds` of a 440 Hz tone at `amplitude` (0 is
    /// silence), at `rate` with `channels`.
    private func wave(seconds: Double, amplitude: Float = 0.5, rate: Double = 48000, channels: AVAudioChannelCount = 1) throws -> URL {
        let url = AppPreviewTestRecording.temporaryURL("music.wav")
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: rate, channels: channels))
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: rate, AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false,
        ])
        let frames = AVAudioFrameCount(seconds * rate)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        for channel in 0..<Int(channels) {
            let data = try #require(buffer.floatChannelData?[channel])
            for frame in 0..<Int(frames) {
                data[frame] = amplitude * sin(2 * .pi * 440 * Float(frame) / Float(rate))
            }
        }
        try file.write(from: buffer)
        return url
    }

    @Test func aMonoFilePlaysOnBothSidesAt44kHz() async throws {
        let url = try wave(seconds: 1.5)
        defer { try? FileManager.default.removeItem(at: url) }
        let samples = try await AppPreviewMusicFile.samples(of: url)
        let frames = samples.count / 2
        #expect(abs(Double(frames) - 1.5 * AppPreviewSynth.sampleRate) < 2000, "\(frames) frames")
        #expect(samples.count.isMultiple(of: 2))
        let middle = frames / 2
        #expect(samples[middle * 2] == samples[middle * 2 + 1], "Left and right are the same tone")
        #expect(abs((samples.map(abs).max() ?? 0) - 0.5) < 0.05)
    }

    @Test func onlyTheFirstFortySecondsAreRead() async throws {
        let url = try wave(seconds: 42, rate: 22050)
        defer { try? FileManager.default.removeItem(at: url) }
        let samples = try await AppPreviewMusicFile.samples(of: url)
        #expect(samples.count <= Int(AppPreviewMusicFile.maximumSeconds * AppPreviewSynth.sampleRate) * 2)
        #expect(samples.count > Int(39 * AppPreviewSynth.sampleRate) * 2)
    }

    @Test func aSilentFileIsSaidPlainly() async throws {
        let url = try wave(seconds: 1, amplitude: 0)
        defer { try? FileManager.default.removeItem(at: url) }
        await #expect(throws: AppPreviewError.silentMusic) {
            try await AppPreviewMusicFile.samples(of: url)
        }
        #expect(AppPreviewError.silentMusic.errorDescription?.isEmpty == false)
    }

    @Test func aFileThatIsntAudioIsUnreadable() async throws {
        let url = AppPreviewTestRecording.temporaryURL("music.m4a")
        try Data("Not music".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        await #expect(throws: AppPreviewError.unreadableMusic) {
            try await AppPreviewMusicFile.samples(of: url)
        }
    }

    @Test func theSoundTrackLoopsTheFile() async throws {
        let url = try wave(seconds: 2, channels: 2)
        defer { try? FileManager.default.removeItem(at: url) }
        let soundtrack = try await AppPreviewSoundtrack.make(.file(url), seconds: 6)
        #expect(soundtrack.frameCount == Int(6 * AppPreviewSynth.sampleRate))
        let late = soundtrack.samples[Int(3.3 * AppPreviewSynth.sampleRate) * 2...Int(3.4 * AppPreviewSynth.sampleRate) * 2]
        #expect(late.contains { abs(Int($0)) > 1000 }, "Still playing after the file ends")
    }
}
