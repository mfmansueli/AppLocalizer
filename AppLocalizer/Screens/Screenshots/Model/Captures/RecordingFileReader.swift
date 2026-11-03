//
//  RecordingFileReader.swift
//  AppLocalizer
//

import AVFoundation
import Foundation

/// Keeps a recording's bytes in a folder, named by their checksum, and
/// reads the video's size and length, or says why it isn't a video.
enum RecordingFileReader {
    /// Whether the bytes look like a QuickTime or MPEG-4 movie: an `ftyp`
    /// box first, or QuickTime's `moov`, `mdat` or `wide`.
    static func isMovie(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let box = String(bytes: data[data.startIndex + 4..<data.startIndex + 8], encoding: .ascii)
        return ["ftyp", "moov", "mdat", "wide", "free"].contains(box ?? "")
    }

    static func store(_ data: Data, in folder: URL) async throws -> RecordingFile {
        guard isMovie(data) else {
            throw AutopilotError(String(localized: "That isn’t a video. Send the recording’s .mov or .mp4 bytes."))
        }
        let id = ScreenshotPNG.checksum(data)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "\(id).mov")
        try data.write(to: url, options: .atomic)
        do {
            let (size, seconds) = try await facts(of: url)
            return RecordingFile(id: id, url: url, pixelSize: size, seconds: seconds)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    /// The video's size as it plays (its transform applied) and its length.
    static func facts(of url: URL) async throws -> (PixelSize, Double) {
        let asset = AVURLAsset(url: url)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
            throw AutopilotError(String(localized: "The recording has no video track. Record with xcrun simctl io booted recordVideo --codec h264."))
        }
        let (natural, transform) = try await track.load(.naturalSize, .preferredTransform)
        let shown = natural.applying(transform)
        let seconds = try await asset.load(.duration).seconds
        guard seconds.isFinite, seconds > 0 else {
            throw AutopilotError(String(localized: "The recording is empty. Stop recordVideo with Control-C (SIGINT) so it finishes the file."))
        }
        return (PixelSize(width: Int(abs(shown.width).rounded()), height: Int(abs(shown.height).rounded())), seconds)
    }
}
