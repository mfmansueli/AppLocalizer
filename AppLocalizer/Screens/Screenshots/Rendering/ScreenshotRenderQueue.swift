//
//  ScreenshotRenderQueue.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation
import Observation

/// Renders the grid's thumbnails one at a time on the main actor (SwiftUI's
/// `ImageRenderer` needs it), yielding between renders so the window stays
/// responsive, and publishes them in small batches. Cached renders appear
/// at once; the rest show a spinner until they're done.
@MainActor
@Observable
final class ScreenshotRenderQueue {
    /// Finished thumbnails by render key.
    private(set) var images: [RenderKey: CGImage] = [:]
    /// Live screenshots' images by live screenshot ID.
    private(set) var liveImages: [String: CGImage] = [:]
    /// Nil when nothing is rendering.
    private(set) var progress: ScreenshotRenderProgress?

    @ObservationIgnored let cache: ScreenshotRenderCache
    /// DEBUG scenes stop after this many renders to show progress.
    @ObservationIgnored var holdCount: Int?
    @ObservationIgnored private let captureImage: (ScreenshotCapture, Int) async -> CGImage?
    @ObservationIgnored private let liveImage: (LiveScreenshot, Int) async -> CGImage?
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var batch: [RenderKey: CGImage] = [:]

    static let batchSize = 6

    init(
        cache: ScreenshotRenderCache,
        holdCount: Int? = nil,
        captureImage: @escaping (ScreenshotCapture, Int) async -> CGImage?,
        liveImage: @escaping (LiveScreenshot, Int) async -> CGImage?
    ) {
        self.cache = cache
        self.holdCount = holdCount
        self.captureImage = captureImage
        self.liveImage = liveImage
    }

    var isRendering: Bool { progress != nil }

    /// Renders `jobs` at `pixelWidth` wide, skipping those already done.
    /// Replaces whatever was queued before.
    func render(_ jobs: [RenderJob], pixelWidth: Int) {
        task?.cancel()
        let todo = jobs.filter { images[$0.key] == nil }
        guard !todo.isEmpty else {
            progress = nil
            return
        }
        progress = ScreenshotRenderProgress(done: jobs.count - todo.count, total: jobs.count)
        task = Task { [weak self] in
            await self?.run(todo, pixelWidth: pixelWidth)
        }
    }

    /// Loads live screenshots' images that aren't loaded yet.
    func loadLive(_ screenshots: [LiveScreenshot], pixelWidth: Int) {
        let missing = screenshots.filter { liveImages[$0.id] == nil }
        guard !missing.isEmpty else { return }
        Task { [weak self] in
            for screenshot in missing {
                guard let self, let image = await liveImage(screenshot, pixelWidth) else { continue }
                liveImages[screenshot.id] = image
            }
        }
    }

    /// One render at a larger size, for the viewer; cached like the rest.
    func largeImage(for job: RenderJob, pixelWidth: Int) async -> CGImage? {
        if let cached = await cache.load(job.key, width: pixelWidth) { return cached }
        let capture = await loadCapture(for: job, pixelWidth: pixelWidth)
        let companion = await loadCompanion(for: job, pixelWidth: pixelWidth)
        guard let image = ScreenshotImageRenderer.image(layout: job.layout, capture: capture, companion: companion, pixelWidth: pixelWidth)
        else { return nil }
        cache.store(image, key: job.key, width: pixelWidth)
        return image
    }

    /// A live screenshot at a larger size, for a viewer; not kept with the
    /// thumbnails.
    func largeLiveImage(_ screenshot: LiveScreenshot, pixelWidth: Int) async -> CGImage? {
        await liveImage(screenshot, pixelWidth)
    }

    func cancel() {
        task?.cancel()
        task = nil
        progress = nil
    }

    private func run(_ jobs: [RenderJob], pixelWidth: Int) async {
        for job in jobs {
            if Task.isCancelled { return }
            if let holdCount, let progress, progress.done >= holdCount {
                flush()
                return
            }
            if let image = await cache.load(job.key, width: pixelWidth) {
                batch[job.key] = image
            } else {
                let capture = await loadCapture(for: job, pixelWidth: pixelWidth)
                let companion = await loadCompanion(for: job, pixelWidth: pixelWidth)
                if Task.isCancelled { return }
                if let image = ScreenshotImageRenderer.image(layout: job.layout, capture: capture, companion: companion, pixelWidth: pixelWidth) {
                    cache.store(image, key: job.key, width: pixelWidth)
                    batch[job.key] = image
                }
                await Task.yield()
            }
            progress?.done += 1
            if batch.count >= Self.batchSize { flush() }
        }
        flush()
        progress = nil
    }

    private func loadCapture(for job: RenderJob, pixelWidth: Int) async -> CGImage? {
        guard let capture = job.capture else { return nil }
        return await captureImage(capture, pixelWidth)
    }

    private func loadCompanion(for job: RenderJob, pixelWidth: Int) async -> CGImage? {
        guard let companion = job.companion else { return nil }
        return await captureImage(companion, pixelWidth)
    }

    private func flush() {
        guard !batch.isEmpty else { return }
        images.merge(batch) { _, new in new }
        batch = [:]
    }
}
