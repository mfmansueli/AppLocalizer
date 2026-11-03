//
//  ExtrasArtworkLoop.swift
//  AppLocalizer
//

import Foundation

/// A header or search image's motion loop: the silent 20-second movie,
/// 30 fps, whose first frame is the image (the poster).
struct ExtrasArtworkLoop: Codable, Hashable, Sendable {
    /// The movie's checksum: its name in the Extras folder, `.mov`.
    var fileID: String
    var byteCount: Int
    var seconds: Double
    var framesPerSecond: Int
    /// "H.264" or "HEVC".
    var codec: String
    /// The last frame matches the first.
    var isSeamless: Bool

    static let pathExtension = "mov"

    /// "0:20 loop".
    var chipTitle: String {
        String(localized: "\(AutopilotRun.timeTitle(seconds)) loop")
    }
}
