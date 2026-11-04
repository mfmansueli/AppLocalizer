//
//  ArtworkWebRenderer.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Renders Claude Design's header and search pages: a few offscreen web
/// views (`ArtworkWebPage`), lent out one render or one loop at a time, so
/// up to `width` render side by side. They close a minute after the last
/// render.
@MainActor
final class ArtworkWebRenderer {
    /// One page more than the loops draw at once, so a still never waits
    /// for a loop to finish.
    static let shared = ArtworkWebRenderer(width: ArtworkLoopJob.width + 1)

    /// How many pages render at once.
    let width: Int
    private var idle: [ArtworkWebPage] = []
    private var made = 0
    private var waiting: [CheckedContinuation<ArtworkWebPage, Never>] = []
    private var fontCSS: String?
    private var closing: Task<Void, Never>?

    /// How long idle pages stay open.
    static let idleLimit: Duration = .seconds(60)

    init(width: Int = 3) {
        self.width = max(1, width)
    }

    /// `request` rendered: the image at its width, flattened to opaque RGB,
    /// and its measure; `behindText` adds what's behind the text, and
    /// `checksMotion` which text moves during the loop.
    func render(_ request: ArtworkWebRequest, behindText: Bool = false, checksMotion: Bool = false) async throws -> ArtworkWebRender {
        try await withPage { page in
            let measure = try await self.load(request, on: page)
            let drawn = try await page.snapshot(width: request.outputWidth)
            guard let image = ScreenshotImageRenderer.flattened(drawn, width: request.outputWidth, height: request.outputHeight) else {
                throw ArtworkWebError.snapshotFailed
            }
            var render = ArtworkWebRender(image: image, measure: measure)
            if behindText {
                try await page.setTextHidden(true)
                render.behindText = try await page.snapshot(width: ArtworkPixels.maximumWidth)
                try await page.setTextHidden(false)
            }
            if checksMotion, measure.moves { render.moving = try await Self.moving(on: page) }
            page.clear()
            return render
        }
    }

    /// Where everything lands and how the text fits, without drawing it.
    func measure(_ request: ArtworkWebRequest) async throws -> ArtworkWebMeasure {
        try await withPage { page in
            let measure = try await self.load(request, on: page)
            page.clear()
            return measure
        }
    }

    /// Lends a page, loaded with `request`, to `body`: a loop steps it
    /// frame by frame.
    func withLoadedPage<T>(_ request: ArtworkWebRequest, _ body: @MainActor (ArtworkWebPage, ArtworkWebMeasure) async throws -> T) async throws -> T {
        try await withPage { page in
            let measure = try await self.load(request, on: page)
            defer { page.clear() }
            return try await body(page, measure)
        }
    }

    // MARK: - Pages

    private func load(_ request: ArtworkWebRequest, on page: ArtworkWebPage) async throws -> ArtworkWebMeasure {
        let css = fontCSS ?? ArtworkWebFonts.css
        fontCSS = css
        return try await page.load(request, fontCSS: css)
    }

    private func withPage<T>(_ body: @MainActor (ArtworkWebPage) async throws -> T) async throws -> T {
        let page = try await borrow()
        do {
            let result = try await body(page)
            giveBack(page)
            return result
        } catch {
            giveBack(page)
            throw error
        }
    }

    private func borrow() async throws -> ArtworkWebPage {
        closing?.cancel()
        closing = nil
        if let page = idle.popLast() { return page }
        if made < width {
            made += 1
            do {
                return try await ArtworkWebPage(rules: ArtworkWebBlocking.list())
            } catch {
                made -= 1
                throw error
            }
        }
        return await withCheckedContinuation { waiting.append($0) }
    }

    private func giveBack(_ page: ArtworkWebPage) {
        if !waiting.isEmpty {
            waiting.removeFirst().resume(returning: page)
            return
        }
        idle.append(page)
        guard idle.count == made else { return }
        closing = Task { [weak self] in
            try? await Task.sleep(for: Self.idleLimit)
            guard !Task.isCancelled, let self, idle.count == self.made else { return }
            for page in idle { page.close() }
            idle = []
            made = 0
            // Fonts uploaded meanwhile come in with the next pages.
            fontCSS = nil
        }
    }

    /// The text and icon that move: their boxes at four moments against
    /// the first.
    private static func moving(on page: ArtworkWebPage) async throws -> [ArtworkWebMarker] {
        let loop = Double(AutopilotArtworkMotion.loopSeconds)
        let start = try await page.textBoxes(at: 0)
        var moved: Set<String> = []
        for moment in [0.2, 0.4, 0.6, 0.8] {
            let boxes = try await page.textBoxes(at: loop * moment)
            for (first, now) in zip(start, boxes) where first.marker == now.marker {
                let shift = max(abs(first.x - now.x), abs(first.y - now.y), abs(first.width - now.width), abs(first.height - now.height))
                if shift > 2 { moved.insert(first.marker) }
            }
        }
        try await page.seek(to: 0)
        return ArtworkWebMarker.allCases.filter { moved.contains($0.rawValue) }
    }
}
