//
//  ArtworkLoopRenderer.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import SwiftUI

/// Makes the header or search artwork's 20-second motion loop from its
/// layout: slow light and scene, a gentle float of the phone, the name and
/// headline still. 600 frames at 30 fps, frame i at i ÷ 599 of the way
/// through, so the last frame is the first and the loop has no jump; the
/// first frame is the poster (the PNG).
@MainActor
enum ArtworkLoopRenderer {
    static var frameCount: Int { AutopilotArtworkMotion.loopSeconds * AutopilotArtworkMotion.loopFramesPerSecond }

    /// Where frame `index` of `count` is in the loop: 0 for the first, 1
    /// (the same as 0) for the last.
    static func phase(ofFrame index: Int, count: Int) -> Double {
        count > 1 ? Double(index) / Double(count - 1) : 0
    }

    /// Writes the loop to `url`; `frames` limits it (for tests).
    static func write(
        layout: ArtworkLayout, captures: [Int: CGImage], icon: CGImage?, to url: URL, frames: Int? = nil
    ) async throws -> ArtworkLoopFacts {
        guard let layers = layers(layout: layout, captures: captures, icon: icon) else { throw ArtworkLoopError.layersFailed }
        return try await encode(layers, layout: layout, frames: frames ?? frameCount, to: url)
    }

    /// Draws and encodes every frame off the main actor.
    @concurrent
    nonisolated static func encode(_ layers: ArtworkLoopLayers, layout: ArtworkLayout, frames count: Int, to url: URL) async throws -> ArtworkLoopFacts {
        let rate = AutopilotArtworkMotion.loopFramesPerSecond
        let writer = try ArtworkLoopWriter(output: url, size: layout.pixelSize, framesPerSecond: rate)
        do {
            for index in 0..<count {
                let phase = count > 1 ? Double(index) / Double(count - 1) : 0
                try await writer.appendFrame { context in
                    layers.draw(layout, phase: phase, in: context)
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

    /// The parts that stay still, each at full size.
    static func layers(layout: ArtworkLayout, captures: [Int: CGImage], icon: CGImage?) -> ArtworkLoopLayers? {
        guard let background = render(ArtworkView(layout: layout, captures: captures, icon: icon, layers: .background), layout: layout, isOpaque: true),
              let text = render(ArtworkView(layout: layout, captures: captures, icon: icon, layers: .text), layout: layout, isOpaque: false)
        else { return nil }
        let phones = layout.phones.isEmpty
            ? nil
            : render(ArtworkView(layout: layout, captures: captures, icon: icon, layers: .phones), layout: layout, isOpaque: false)
        return ArtworkLoopLayers(background: background, phones: phones, text: text)
    }

    private static func render(_ view: ArtworkView, layout: ArtworkLayout, isOpaque: Bool) -> CGImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = isOpaque
        renderer.proposedSize = ProposedViewSize(layout.size)
        return renderer.cgImage
    }
}
