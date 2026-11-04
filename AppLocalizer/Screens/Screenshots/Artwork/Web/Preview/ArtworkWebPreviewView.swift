//
//  ArtworkWebPreviewView.swift
//  AppLocalizer
//

import AppKit

/// A Claude Design page playing live in the viewer: its own web view,
/// zoomed so the whole canvas fills the view, its CSS motion seeking,
/// playing and pausing as its `playback` says.
@MainActor
final class ArtworkWebPreviewView: NSView {
    private var page: ArtworkWebPage?
    private var loaded: ArtworkWebRequest?
    private var loading: Task<Void, Never>?
    private var playback = ArtworkLoopClock.Playback(isPlaying: true, seconds: 0, change: 0)
    /// The playback the page was last told, so each is told once.
    private var applied: ArtworkLoopClock.Playback?
    /// Seeks and plays one after another, in order.
    private var applying: Task<Void, Never>?
    /// Whether the page loaded: false while it loads, or when it failed.
    private(set) var isReady = false
    /// Called as a page starts loading, and once it's loaded and filled in.
    var willLoad: () -> Void = {}
    var didLoad: () -> Void = {}

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Loads `request` (once per request) and seeks, plays or pauses it
    /// as `playback` says.
    func show(_ request: ArtworkWebRequest, playback: ArtworkLoopClock.Playback) {
        self.playback = playback
        guard loaded?.html != request.html || loaded?.locale != request.locale || loaded?.headline != request.headline
            || loaded?.captures != request.captures
        else {
            apply()
            return
        }
        loaded = request
        isReady = false
        loading?.cancel()
        loading = Task { [weak self] in
            guard let self else { return }
            willLoad()
            do {
                let page: ArtworkWebPage = if let existing = self.page { existing } else { try await makePage() }
                _ = try await page.load(request, fontCSS: ArtworkWebFonts.css)
                guard !Task.isCancelled else { return }
                page.fit(width: bounds.width)
                isReady = true
                applied = nil
                apply()
                didLoad()
            } catch {
                isReady = false
            }
        }
    }

    private func makePage() async throws -> ArtworkWebPage {
        let page = try await ArtworkWebPage(rules: ArtworkWebBlocking.list(), offscreen: false)
        page.webView.frame = bounds
        page.webView.autoresizingMask = [.width, .height]
        addSubview(page.webView)
        self.page = page
        return page
    }

    /// Tells the page the latest playback: where to be, and whether it
    /// plays from there.
    private func apply() {
        guard let page, isReady, applied != playback else { return }
        let wanted = playback
        applied = wanted
        let previous = applying
        applying = Task {
            await previous?.value
            try? await page.seek(to: wanted.seconds)
            try? await page.setPlaying(wanted.isPlaying)
        }
    }

    override func layout() {
        super.layout()
        page?.webView.frame = bounds
        page?.fit(width: bounds.width)
    }

    /// Stops the page when the viewer goes.
    func close() {
        loading?.cancel()
        applying?.cancel()
        page?.close()
        page?.webView.removeFromSuperview()
        page = nil
        loaded = nil
    }
}
