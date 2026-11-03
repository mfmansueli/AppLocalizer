//
//  AppPreviewMusicFile.swift
//  AppLocalizer
//

import AVFoundation
import Foundation

/// Reads the person's own music file as the App Preview needs it:
/// interleaved stereo at 44.1 kHz (a mono file plays on both sides), at
/// most `maximumSeconds` of it.
enum AppPreviewMusicFile {
    /// More than an App Preview ever needs.
    static let maximumSeconds = 40.0

    static func samples(of url: URL) async throws -> [Float] {
        let (reader, output) = try await reader(for: url)
        let provider = reader.outputProvider(for: output)
        do {
            try reader.start()
        } catch {
            throw AppPreviewError.unreadableMusic
        }
        defer { if reader.status == .reading { reader.cancelReading() } }
        var samples: [Float] = []
        let limit = Int(maximumSeconds * AppPreviewSynth.sampleRate) * 2
        do {
            while samples.count < limit, let sample = try await provider.next() {
                guard case let .dataBuffer(data) = sample.content else { continue }
                guard let chunk = data.withUnsafeBlockBuffer({ floats(in: $0) }) else { throw AppPreviewError.unreadableMusic }
                samples += chunk
            }
        } catch {
            throw readError(error)
        }
        guard samples.count >= 2, samples.contains(where: { $0 != 0 }) else { throw AppPreviewError.silentMusic }
        return Array(samples.prefix(limit - limit % 2))
    }

    /// A reader of the file's first audio track, as 32-bit float stereo.
    private static func reader(for url: URL) async throws -> (AVAssetReader, AVAssetReaderTrackOutput) {
        let asset = AVURLAsset(url: url)
        let tracks: [AVAssetTrack]
        do {
            tracks = try await asset.loadTracks(withMediaType: .audio)
        } catch {
            throw readError(error)
        }
        guard let track = tracks.first, let reader = try? AVAssetReader(asset: asset) else {
            throw tracks.isEmpty ? AppPreviewError.silentMusic : AppPreviewError.unreadableMusic
        }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: AppPreviewSynth.sampleRate,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ])
        guard reader.canAdd(output) else { throw AppPreviewError.unreadableMusic }
        reader.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: maximumSeconds, preferredTimescale: 600))
        return (reader, output)
    }

    /// The block's samples; nil when they can't be copied.
    private static func floats(in block: CMBlockBuffer) -> [Float]? {
        let count = CMBlockBufferGetDataLength(block) / MemoryLayout<Float>.size
        guard count > 0 else { return [] }
        var chunk = [Float](repeating: 0, count: count)
        let status = chunk.withUnsafeMutableBytes { bytes in
            CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: count * MemoryLayout<Float>.size, destination: bytes.baseAddress!)
        }
        return status == noErr ? chunk : nil
    }

    /// Cancelling stays cancelling and AppLocalizer's own errors stay;
    /// anything else is a file that can't be read.
    private static func readError(_ error: any Error) -> any Error {
        error is CancellationError || error is AppPreviewError ? error : AppPreviewError.unreadableMusic
    }
}
