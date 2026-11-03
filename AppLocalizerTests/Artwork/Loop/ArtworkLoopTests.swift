//
//  ArtworkLoopTests.swift
//  AppLocalizerTests
//

#if DEBUG
import AVFoundation
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// The header and search motion loop (board 32): 600 frames at 30 fps,
/// frame i at i ÷ 599 of the way through, so its first and last frames
/// match and it repeats without a jump; the checker tells a loop that
/// jumps.
@MainActor
@Suite("Artwork motion loop")
struct ArtworkLoopTests {
    private typealias Fixtures = ArtworkCheckFixtures

    private static func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "artwork-loop-\(UUID().uuidString).mov")
    }

    @Test func theLastFrameIsTheFirst() {
        #expect(ArtworkLoopRenderer.frameCount == 600)
        #expect(ArtworkLoopRenderer.phase(ofFrame: 0, count: 600) == 0)
        #expect(ArtworkLoopRenderer.phase(ofFrame: 599, count: 600) == 1)
        #expect(ArtworkLoopRenderer.phase(ofFrame: 0, count: 1) == 0)
        // Everything that moves is back where it started at the end.
        #expect(abs(ArtworkScene.drift(0) - ArtworkScene.drift(1)) < 1e-12)
        #expect(ArtworkScene.drift(0) == 0)
        #expect(abs(ArtworkScene.drift(0.5) - 1) < 1e-12)
        #expect(abs(ArtworkScene.floatOffset(0, height: 2560) - ArtworkScene.floatOffset(1, height: 2560)) < 1e-9)
        // The phone floats up by 2.6% of the height, twice a loop.
        #expect(abs(ArtworkScene.floatOffset(0.25, height: 1000) + 26) < 1e-9)
    }

    /// A real loop of the search artwork with its scene, shortened to nine
    /// frames: its first and last frames match, its middle one doesn't.
    @Test(arguments: [AutopilotArtworkShow.phone, .scene])
    func aRenderedLoopIsSeamless(shows: AutopilotArtworkShow) async throws {
        let layout = Fixtures.layout(.search, headline: "Your week, sorted", shows: shows, isMotion: true)
        #expect(layout.scene?.isMotion == true)
        let captures = Dictionary(uniqueKeysWithValues: layout.phones.compactMap { phone in Fixtures.capture().map { (phone.slot, $0) } })
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let facts = try await ArtworkLoopRenderer.write(layout: layout, captures: captures, icon: nil, to: url, frames: 9)
        #expect(facts.frames == 9)
        #expect(facts.framesPerSecond == 30)
        #expect(["H.264", "HEVC"].contains(facts.codec))

        let check = await ArtworkLoopChecker.check(url, size: layout.pixelSize)
        #expect(check.isSeamless)
        #expect(!check.problems.contains { $0.contains("doesn’t match the first") })
        #expect(!check.problems.contains { $0.contains("has sound") || $0.contains("fps") || $0.contains(" × ") })

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 320, height: 320)
        let first = try await generator.image(at: .zero).image
        let middle = try await generator.image(at: CMTime(value: 4, timescale: 30)).image
        let last = try await generator.image(at: CMTime(value: 8, timescale: 30)).image
        let seam = try #require(ArtworkLoopChecker.difference(first, last))
        let halfway = try #require(ArtworkLoopChecker.difference(first, middle))
        #expect(seam <= ArtworkLoopChecker.seamTolerance)
        #expect(halfway > seam, "It moves in between")
    }

    @Test func aLoopThatJumpsIsCaught() async throws {
        let url = Self.temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let size = PixelSize(width: 320, height: 240)
        try await Self.writeJump(to: url, size: size)
        let check = await ArtworkLoopChecker.check(url, size: size)
        #expect(!check.isSeamless)
        #expect(check.problems.contains("The last frame doesn’t match the first, so the loop jumps when it repeats."))
        #expect(check.problems.contains { $0.hasPrefix("The loop runs 0:00") }, "Three frames aren’t 20 seconds")
    }

    /// Two dark frames, then a light one.
    @concurrent
    private nonisolated static func writeJump(to url: URL, size: PixelSize) async throws {
        let writer = try ArtworkLoopWriter(output: url, size: size, framesPerSecond: 30)
        for index in 0..<3 {
            try await writer.appendFrame { context in
                let level: CGFloat = index == 2 ? 0.95 : 0.05
                context.setFillColor(CGColor(red: level, green: level, blue: level, alpha: 1))
                context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
        }
        try await writer.finish()
    }
}
#endif
