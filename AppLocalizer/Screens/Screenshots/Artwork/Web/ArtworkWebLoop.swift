//
//  ArtworkWebLoop.swift
//  AppLocalizer
//

import CoreGraphics
import CryptoKit
import Foundation

/// Makes a Claude Design page's 20-second motion loop: the page's own CSS
/// (and SVG) animation, paused at each frame's moment and drawn. 600 frames
/// at 30 fps, frame i at i ÷ 599 of the way through like
/// `ArtworkLoopRenderer`, so the last frame is the first and the first is
/// the poster.
enum ArtworkWebLoop {
    /// Changes whenever a page's loop would come out differently, so loops
    /// made before aren't reused (`ArtworkLoopIndex`).
    static let version = 2

    /// The key a page's loop is remembered by: its poster, its page, its
    /// language and that language's phrases, so two pages with the same
    /// first frame but other motion, or other words later in the loop
    /// (pt-BR's and pt-PT's phrases fade in after the poster), never share.
    static func posterKey(poster: String, html: String, locale: String = "", phrases: [String: String] = [:]) -> String {
        let words = phrases.sorted { $0.key < $1.key }.map { "\($0.key)\u{1F}\($0.value)" }.joined(separator: "\u{1E}")
        let digest = SHA256.hash(data: Data((html + "\u{1D}" + locale + "\u{1D}" + words).utf8)).map { String(format: "%02x", $0) }.joined()
        return "\(poster)-web\(version)-\(digest.prefix(16))"
    }

    /// Writes `request`'s loop to `url`; `frames` limits it (for tests).
    @MainActor
    static func write(
        _ request: ArtworkWebRequest, to url: URL, frames: Int? = nil, renderer: ArtworkWebRenderer = .shared
    ) async throws -> ArtworkLoopFacts {
        let count = frames ?? ArtworkLoopRenderer.frameCount
        return try await renderer.withLoadedPage(request) { page, _ in
            try await encode(page: page, size: request.pixelSize, frames: count, to: url)
        }
    }

    /// Steps and draws every frame on the page (the main actor), and
    /// encodes them off it.
    @concurrent
    private static func encode(page: ArtworkWebPage, size: PixelSize, frames count: Int, to url: URL) async throws -> ArtworkLoopFacts {
        let rate = AutopilotArtworkMotion.loopFramesPerSecond
        let seconds = Double(AutopilotArtworkMotion.loopSeconds)
        let writer = try ArtworkLoopWriter(output: url, size: size, framesPerSecond: rate)
        let full = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        do {
            for index in 0..<count {
                let phase = count > 1 ? Double(index) / Double(count - 1) : 0
                let image = try await page.frame(at: phase * seconds, width: size.width)
                try await writer.appendFrame { context in
                    context.draw(image, in: full)
                }
            }
            try await writer.finish()
        } catch {
            writer.cancel()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
        let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        return ArtworkLoopFacts(
            frames: count, framesPerSecond: rate, seconds: Double(count) / Double(rate), byteCount: bytes, codec: writer.codecTitle
        )
    }
}
