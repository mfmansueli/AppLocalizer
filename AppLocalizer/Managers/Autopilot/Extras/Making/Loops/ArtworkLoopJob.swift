//
//  ArtworkLoopJob.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One loop to draw: which file it belongs to, what it's drawn from (its
/// still layers ready to draw, or a Claude Design page), and where its
/// draft goes. Everything it holds can cross to the task that draws it.
struct ArtworkLoopJob: Sendable {
    /// The file's place in the maker's list, and its language's.
    var fileIndex: Int
    var localeIndex: Int
    /// The key it's remembered by in `ArtworkLoopIndex`.
    var poster: String
    var place: String
    var size: PixelSize
    var source: ArtworkLoopSource
    var draft: URL

    /// What drawing it gave back.
    struct Drawn: Sendable {
        var job: ArtworkLoopJob
        var facts: ArtworkLoopFacts
    }

    /// Draws and encodes every frame: the layers off the main actor, a
    /// page stepped on it and encoded off it.
    func draw() async throws -> Drawn {
        let facts = switch source {
        case let .layers(layers, layout):
            try await ArtworkLoopRenderer.encode(layers, layout: layout, frames: ArtworkLoopRenderer.frameCount, to: draft)
        case let .page(request):
            try await ArtworkWebLoop.write(request, to: draft)
        }
        return Drawn(job: self, facts: facts)
    }

    /// How many loops draw at once: two, three on a Mac with many cores;
    /// each frame is drawn on one core, and the movie encoder has room.
    static var width: Int {
        min(3, max(2, ProcessInfo.processInfo.activeProcessorCount / 4))
    }
}
