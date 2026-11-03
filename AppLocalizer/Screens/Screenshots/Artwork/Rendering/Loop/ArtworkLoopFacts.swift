//
//  ArtworkLoopFacts.swift
//  AppLocalizer
//

import Foundation

/// What was written for a motion loop.
struct ArtworkLoopFacts: Hashable, Sendable {
    var frames: Int
    var framesPerSecond: Int
    var seconds: Double
    var byteCount: Int
    /// "H.264" or "HEVC".
    var codec: String
}
