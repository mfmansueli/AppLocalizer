//
//  ArtworkLoopIndexTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The loops made before, by poster: kept beside the files, read back, and
/// left alone once the loop maker changes.
@MainActor
@Suite("Artwork loop index")
struct ArtworkLoopIndexTests {
    private static let loop = ExtrasArtworkLoop(
        fileID: "mov-1", byteCount: 18_000_000, seconds: 20, framesPerSecond: 30, codec: "H.264", isSeamless: true
    )

    private static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "loop-index-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func aLoopIsReadBackByItsPoster() throws {
        let folder = try Self.folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        var index = ArtworkLoopIndex()
        index.remember(Self.loop, forPoster: "png-1")
        try index.save(to: folder)

        let read = ArtworkLoopIndex.load(from: folder)
        #expect(read == index)
        #expect(read.loop(forPoster: "png-1") == Self.loop)
        #expect(read.loop(forPoster: "png-2") == nil)
    }

    @Test func aNewLoopMakerDoesntReuseOldLoops() {
        var index = ArtworkLoopIndex()
        index.remember(Self.loop, forPoster: "png-1", version: ArtworkLoopRenderer.version)
        #expect(index.loop(forPoster: "png-1", version: ArtworkLoopRenderer.version + 1) == nil)
        #expect(ArtworkLoopIndex.key(poster: "png-1", version: 3) == "png-1-v3")
    }

    @Test func noIndexOrABrokenOneIsEmpty() throws {
        let folder = try Self.folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(ArtworkLoopIndex.load(from: folder).loops.isEmpty)
        try Data("not json".utf8).write(to: folder.appending(path: ArtworkLoopIndex.fileName))
        #expect(ArtworkLoopIndex.load(from: folder).loops.isEmpty)
    }
}
#endif
