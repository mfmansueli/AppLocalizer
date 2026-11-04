//
//  ArtworkWebPage.swift
//  AppLocalizer
//

import AppKit
import WebKit

/// One web view that renders Claude Design pages. The page's own scripts
/// never run and the network is blocked; AppLocalizer fills it in from its
/// own content world. Offscreen, it sits in a borderless window far off
/// every screen, its view a canvas ÷ the screen's scale in points and
/// zoomed by the same, so one CSS pixel is one pixel of the snapshot.
@MainActor
final class ArtworkWebPage: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    private let window: NSWindow?
    private let assets = ArtworkWebAssets()
    private var loading: CheckedContinuation<Void, any Error>?
    /// The load in flight, so a late timeout leaves a newer one alone.
    private var loadToken = UUID()
    private(set) var size = PixelSize(width: 0, height: 0)

    /// How long a page may take to load and fill in.
    static let loadLimit: Duration = .seconds(30)

    init(rules: WKContentRuleList, offscreen: Bool = true) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.setURLSchemeHandler(assets, forURLScheme: ArtworkWebAssets.scheme)
        configuration.userContentController.add(rules)
        configuration.suppressesIncrementalRendering = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), configuration: configuration)
        if offscreen {
            let window = NSWindow(
                contentRect: CGRect(x: -30000, y: -30000, width: 100, height: 100), styleMask: [.borderless], backing: .buffered, defer: false
            )
            window.isReleasedWhenClosed = false
            window.isExcludedFromWindowsMenu = true
            window.collectionBehavior = [.transient, .ignoresCycle, .stationary]
            window.ignoresMouseEvents = true
            window.hasShadow = false
            window.setAccessibilityElement(false)
            window.setAccessibilityHidden(true)
            window.contentView = webView
            window.orderBack(nil)
            self.window = window
        } else {
            window = nil
        }
        super.init()
        webView.navigationDelegate = self
        webView.setAccessibilityElement(false)
    }

    /// The screen's scale the window draws at.
    private var scale: CGFloat { max(1, window?.backingScaleFactor ?? 2) }

    /// Loads `request`'s page at its canvas, fills it in its language at
    /// its moment, and reads where everything landed.
    func load(_ request: ArtworkWebRequest, fontCSS: String) async throws -> ArtworkWebMeasure {
        let bytes = request.html.utf8.count
        guard bytes <= AutopilotArtworkDesign.maximumBytes else { throw ArtworkWebError.tooLarge(bytes) }
        resize(to: request.pixelSize)
        assets.reset(icon: request.icon, captures: request.captures)
        try await navigate(to: request.html)
        let arguments: [String: Any] = [
            "headline": request.headline, "appName": request.appName, "lang": request.locale,
            "dir": request.isRightToLeft ? "rtl" : "ltr", "time": request.time * 1000,
            "minimumScale": ArtworkLayoutEngine.smallestScale, "fontCSS": fontCSS,
            "primary": request.primaryLocale ?? request.locale, "phrases": request.phrases,
        ]
        let json = try await run(ArtworkWebScript.fill, arguments: arguments)
        guard let data = json?.data(using: .utf8) else { throw ArtworkWebError.scriptFailed("no measure") }
        do {
            return try JSONDecoder().decode(ArtworkWebMeasure.self, from: data)
        } catch {
            throw ArtworkWebError.scriptFailed(error.localizedDescription)
        }
    }

    /// Pauses the page's motion `seconds` into the loop.
    func seek(to seconds: Double) async throws {
        try await run(ArtworkWebScript.seek, arguments: ["time": seconds * 1000])
    }

    /// Where the text and icon are `seconds` into the loop.
    func textBoxes(at seconds: Double) async throws -> [ArtworkWebMeasure.Element] {
        let json = try await run(ArtworkWebScript.textBoxes, arguments: ["time": seconds * 1000])
        guard let data = json?.data(using: .utf8),
              let boxes = try? JSONDecoder().decode([TextBox].self, from: data)
        else { return [] }
        return boxes.map {
            ArtworkWebMeasure.Element(marker: $0.marker, x: $0.x, y: $0.y, width: $0.width, height: $0.height, fits: true, isVisible: true)
        }
    }

    private struct TextBox: Decodable {
        var marker: String
        var x: Double
        var y: Double
        var width: Double
        var height: Double
    }

    /// Plays the page's motion live (an onscreen page) or pauses it.
    func setPlaying(_ playing: Bool) async throws {
        try await run(ArtworkWebScript.play, arguments: ["playing": playing])
    }

    /// An onscreen page's view `width` points wide shows the whole canvas.
    func fit(width: CGFloat) {
        guard window == nil, size.width > 0, width > 0 else { return }
        webView.pageZoom = width / CGFloat(size.width)
    }

    /// Hides the filled-in text, to see what's behind it, or shows it.
    func setTextHidden(_ hidden: Bool) async throws {
        try await run(ArtworkWebScript.hideText, arguments: ["hidden": hidden])
    }

    /// The page as drawn, `width` pixels wide (the canvas's at most).
    func snapshot(width: Int) async throws -> CGImage {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = webView.bounds
        configuration.snapshotWidth = NSNumber(value: Double(min(width, size.width)) / Double(scale))
        configuration.afterScreenUpdates = true
        let image = try await webView.takeSnapshot(configuration: configuration)
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { throw ArtworkWebError.snapshotFailed }
        return cgImage
    }

    /// One frame of the loop, `seconds` in, `width` pixels wide.
    func frame(at seconds: Double, width: Int) async throws -> CGImage {
        try await seek(to: seconds)
        return try await snapshot(width: width)
    }

    /// Drops the page and its files, so nothing lingers between renders.
    func clear() {
        assets.reset(icon: nil, captures: [:])
        webView.loadHTMLString("", baseURL: nil)
    }

    func close() {
        loading?.resume(throwing: CancellationError())
        loading = nil
        webView.stopLoading()
        window?.contentView = nil
        window?.close()
    }

    // MARK: - Helpers

    private func resize(to canvas: PixelSize) {
        guard canvas != size else { return }
        size = canvas
        guard let window else { return }
        let points = CGSize(width: CGFloat(canvas.width) / scale, height: CGFloat(canvas.height) / scale)
        window.setContentSize(points)
        webView.frame = CGRect(origin: .zero, size: points)
        webView.pageZoom = 1 / scale
    }

    /// Runs one of AppLocalizer's scripts; what it returns when that's text.
    @discardableResult
    private func run(_ script: String, arguments: [String: Any]) async throws -> String? {
        do {
            return try await webView.callAsyncJavaScript(script, arguments: arguments, in: nil, contentWorld: .defaultClient) as? String
        } catch {
            throw ArtworkWebError.scriptFailed(error.localizedDescription)
        }
    }

    /// Loads `html`; `ArtworkWebError.timedOut` after `loadLimit`.
    private func navigate(to html: String) async throws {
        let token = UUID()
        loadToken = token
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            loading?.resume(throwing: CancellationError())
            loading = continuation
            webView.loadHTMLString(html, baseURL: URL(string: "\(ArtworkWebAssets.scheme)://page/"))
            Task { [weak self] in
                try? await Task.sleep(for: Self.loadLimit)
                guard let self, loadToken == token, let loading else { return }
                self.loading = nil
                webView.stopLoading()
                loading.resume(throwing: ArtworkWebError.timedOut)
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        finishLoading(nil)
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: any Error) {
        finishLoading(ArtworkWebError.loadFailed(error.localizedDescription))
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: any Error) {
        finishLoading(ArtworkWebError.loadFailed(error.localizedDescription))
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        finishLoading(ArtworkWebError.loadFailed(String(localized: "the page’s process ended")))
    }

    /// Links and other navigations away from the page go nowhere.
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        let scheme = navigationAction.request.url?.scheme
        let isPage = scheme == ArtworkWebAssets.scheme || scheme == "about"
        return isPage && navigationAction.targetFrame?.isMainFrame != false ? .allow : .cancel
    }

    private func finishLoading(_ error: (any Error)?) {
        guard let loading else { return }
        self.loading = nil
        if let error { loading.resume(throwing: error) } else { loading.resume() }
    }
}
