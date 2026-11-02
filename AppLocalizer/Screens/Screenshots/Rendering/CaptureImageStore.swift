//
//  CaptureImageStore.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// Capture images the editors draw their live previews with: the template
/// editor's canvas and stress strip, the caption editor's preview, and the
/// Captures tab's thumbnails and viewer. Loaded once per capture and width;
/// past the pixel budget the ones asked for longest ago go first, so what's
/// on screen stays.
@MainActor
@Observable
final class CaptureImageStore {
    private(set) var images: [String: CGImage] = [:]
    /// Every key asked for, the one asked for longest ago first.
    @ObservationIgnored private var order: [String] = []
    @ObservationIgnored private var requested: Set<String> = []
    @ObservationIgnored private let load: (ScreenshotCapture, Int) async -> CGImage?
    @ObservationIgnored private let pixelBudget: Int

    /// About 200 MB of images: every thumbnail of a Captures tab and a
    /// handful of full-size captures.
    nonisolated static let pixelBudget = 50_000_000

    init(pixelBudget: Int = CaptureImageStore.pixelBudget, load: @escaping (ScreenshotCapture, Int) async -> CGImage?) {
        self.pixelBudget = pixelBudget
        self.load = load
    }

    func image(for capture: ScreenshotCapture?, width: Int) -> CGImage? {
        capture.flatMap { images[Self.key($0, width: width)] }
    }

    /// Loads the captures that aren't loaded or loading yet, one at a
    /// time; the ones already here count as just asked for.
    func request(_ captures: [ScreenshotCapture], width: Int) {
        var missing: [(capture: ScreenshotCapture, key: String)] = []
        for capture in captures {
            let key = Self.key(capture, width: width)
            if requested.contains(key) {
                order.removeAll { $0 == key }
            } else if !missing.contains(where: { $0.key == key }) {
                missing.append((capture, key))
                requested.insert(key)
            }
            order.append(key)
        }
        guard !missing.isEmpty else { return }
        Task { [weak self, load] in
            for (capture, key) in missing {
                guard let image = await load(capture, width), let self, requested.contains(key) else { continue }
                images[key] = image
                evict()
            }
        }
    }

    /// Waits for what's loading (tests).
    func waitUntilLoaded(_ captures: [ScreenshotCapture], width: Int) async {
        while captures.contains(where: { images[Self.key($0, width: width)] == nil }) {
            await Task.yield()
        }
    }

    /// Past the budget, drops the loaded images asked for longest ago; the
    /// newest always stays, however big.
    private func evict() {
        var pixels = images.values.reduce(0) { $0 + $1.width * $1.height }
        var index = 0
        while pixels > pixelBudget, index < order.count - 1 {
            let key = order[index]
            guard let image = images.removeValue(forKey: key) else {
                index += 1
                continue
            }
            pixels -= image.width * image.height
            requested.remove(key)
            order.remove(at: index)
        }
    }

    private static func key(_ capture: ScreenshotCapture, width: Int) -> String {
        "\(capture.id)@\(width)"
    }
}
