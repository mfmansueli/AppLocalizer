//
//  ArtworkWebPreviewZoomTests.swift
//  AppLocalizerTests
//

#if DEBUG
import AppKit
import Foundation
import Testing
@testable import AppLocalizer

/// A Claude Design page playing in a small view (Choose's concept cards)
/// is laid out at a zoom WebKit doesn't enlarge its text at, then scaled
/// down: the text keeps the size it was drawn at.
@MainActor
@Suite("Claude Design pages playing small", .serialized)
struct ArtworkWebPreviewZoomTests {
    @Test func aSmallViewIsLaidOutAtTheLeastZoom() throws {
        let search = AutopilotArtworkKind.search.pixelSize
        let tile = try #require(ArtworkWebPage.fitting(width: 96, canvas: search))
        #expect(tile.zoom == ArtworkWebPage.minimumZoom)
        #expect(tile.size == CGSize(width: CGFloat(search.width) * ArtworkWebPage.minimumZoom, height: CGFloat(search.height) * ArtworkWebPage.minimumZoom))
        let viewer = try #require(ArtworkWebPage.fitting(width: 1200, canvas: search))
        #expect(viewer.size.width == 1200, "Wide enough: laid out at its own width")
        #expect(ArtworkWebPage.fitting(width: 0, canvas: search) == nil)
    }

    /// Bruma's search results on Choose, 96 pt wide: a zoom of 0.025 drew
    /// its 200 px headline at 360 px (WebKit's 9 pt least, unzoomed), and
    /// the headline ran over the app's name.
    @Test func textKeepsItsSizeInASmallView() async throws {
        let page = try await ArtworkWebPage(rules: ArtworkWebBlocking.list(), offscreen: false)
        let window = NSWindow(contentRect: CGRect(x: -4000, y: -4000, width: 400, height: 300), styleMask: [.borderless], backing: .buffered, defer: false)
        defer {
            page.close()
            window.close()
        }
        window.contentView?.addSubview(page.webView)
        let html = ArtworkWebFixtures.searchPage(extraBody: "<p id=\"probe\" style=\"position: absolute; top: 0; font: 400 60px system-ui\">Probe</p>")
        _ = try await page.load(ArtworkWebFixtures.request(html), fontCSS: ArtworkWebFonts.css)
        let size = try #require(page.fit(width: 96))
        page.webView.frame = CGRect(origin: .zero, size: size)
        let font = try await page.webView.callAsyncJavaScript(
            "return getComputedStyle(document.getElementById('probe')).fontSize", arguments: [:], in: nil, contentWorld: .defaultClient
        ) as? String
        #expect(font == "60px")
    }
}
#endif
