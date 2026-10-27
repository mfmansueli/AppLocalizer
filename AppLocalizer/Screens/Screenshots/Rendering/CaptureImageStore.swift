//
//  CaptureImageStore.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// Capture images the editors draw their live previews with: the template
/// editor's canvas and stress strip, and the caption editor's preview.
/// Loaded once per capture and width, and dropped when too many pile up.
@MainActor
@Observable
final class CaptureImageStore {
    private(set) var images: [String: CGImage] = [:]
    @ObservationIgnored private var requested: Set<String> = []
    @ObservationIgnored private let load: (ScreenshotCapture, Int) async -> CGImage?

    /// How many images it keeps before starting over.
    static let limit = 60

    init(load: @escaping (ScreenshotCapture, Int) async -> CGImage?) {
        self.load = load
    }

    func image(for capture: ScreenshotCapture?, width: Int) -> CGImage? {
        capture.flatMap { images[Self.key($0, width: width)] }
    }

    /// Loads the captures that aren't loaded or loading yet, one at a
    /// time.
    func request(_ captures: [ScreenshotCapture], width: Int) {
        let missing = captures.filter { !requested.contains(Self.key($0, width: width)) }
        guard !missing.isEmpty else { return }
        if requested.count + missing.count > Self.limit {
            images = [:]
            requested = []
        }
        missing.forEach { requested.insert(Self.key($0, width: width)) }
        Task { [weak self, load] in
            for capture in missing {
                guard let image = await load(capture, width) else { continue }
                self?.images[Self.key(capture, width: width)] = image
            }
        }
    }

    /// Waits for what's loading (tests).
    func waitUntilLoaded(_ captures: [ScreenshotCapture], width: Int) async {
        while captures.contains(where: { images[Self.key($0, width: width)] == nil }) {
            await Task.yield()
        }
    }

    private static func key(_ capture: ScreenshotCapture, width: Int) -> String {
        "\(capture.id)@\(width)"
    }
}
