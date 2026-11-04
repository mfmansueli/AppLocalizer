//
//  ArtworkLoopJob.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One loop to draw: which file it belongs to, its still layers ready to
/// draw, and where its draft goes. Everything it holds can cross to the
/// task that draws it.
struct ArtworkLoopJob: Sendable {
    /// The file's place in the maker's list, and its language's.
    var fileIndex: Int
    var localeIndex: Int
    var poster: String
    var place: String
    var layout: ArtworkLayout
    var layers: ArtworkLoopLayers
    var draft: URL

    /// What drawing it gave back.
    struct Drawn: Sendable {
        var job: ArtworkLoopJob
        var facts: ArtworkLoopFacts
    }

    /// Draws and encodes every frame, off the main actor.
    func draw() async throws -> Drawn {
        let facts = try await ArtworkLoopRenderer.encode(layers, layout: layout, frames: ArtworkLoopRenderer.frameCount, to: draft)
        return Drawn(job: self, facts: facts)
    }

    /// How many loops draw at once: two, three on a Mac with many cores;
    /// each frame is drawn on one core, and the movie encoder has room.
    static var width: Int {
        min(3, max(2, ProcessInfo.processInfo.activeProcessorCount / 4))
    }
}
