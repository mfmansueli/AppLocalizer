//
//  ArtworkWebRendererTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Claude Design's pages rendered by AppLocalizer: at the canvas's exact
/// size, filled in for the language, the text fitted, the page's own
/// scripts and the network kept out, the motion stepped.
@MainActor
@Suite("Claude Design pages rendered", .serialized)
struct ArtworkWebRendererTests {
    let renderer = ArtworkWebRenderer(width: 1)

    @Test func itRendersAtTheCanvassExactSizeOpaque() async throws {
        let render = try await renderer.render(ArtworkWebFixtures.request(pixelWidth: nil))
        #expect(render.image.width == 3840)
        #expect(render.image.height == 2560)
        #expect(!ArtworkPixels.hasAlphaChannel(render.image))
        let corner = ArtworkWebFixtures.color(in: render.image, x: 20, y: 20)
        #expect(ArtworkWebFixtures.isClose(corner, ArtworkWebFixtures.background))
    }

    @Test func aSmallerWidthKeepsTheRatio() async throws {
        let render = try await renderer.render(ArtworkWebFixtures.request(kind: .header, pixelWidth: 480))
        #expect(render.image.width == 480)
        #expect(render.image.height == 206)
    }

    @Test func itFillsInTheTextAndSaysWhereItLanded() async throws {
        let render = try await renderer.render(ArtworkWebFixtures.request(headline: "Calm"))
        let headline = try #require(render.measure.headline)
        #expect(headline.text == "Calm")
        #expect(headline.fits)
        #expect(headline.fitScale == 1)
        #expect(abs(headline.x - 200) < 4, "The text's own box starts at the h1's left edge")
        #expect(headline.y > 260 && headline.y < 340, "Its glyphs, which reach a little past a 1.0 line height")
        #expect(headline.width < 1600, "Its own box, not the h1's")
        #expect(TemplateColor(headline.color ?? "").map { ArtworkWebFixtures.isClose($0, .white) } == true)
        let name = try #require(render.measure.elements(.appName).first)
        #expect(name.text == "Alba")
        let capture = try #require(render.measure.elements(.capture).first)
        #expect(capture.slot == 1)
        #expect(capture.isLoaded == true)
        #expect(abs(capture.x - (3840 - 400 - 900)) < 2)
        #expect(render.measure.elements(.icon).first?.isLoaded == true)
        // The capture is the PNG served for slot 1: orange-red.
        let inCapture = ArtworkWebFixtures.color(in: render.image, x: capture.x + 450, y: capture.y + 900)
        #expect(ArtworkWebFixtures.isClose(inCapture, TemplateColor(red: 0.9, green: 0.3, blue: 0.2), within: 0.08))
    }

    @Test func longTextShrinksToFitItsBox() async throws {
        let long = "Tägliche motivierende Zitate für jeden einzelnen Morgen deiner Woche"
        let render = try await renderer.render(ArtworkWebFixtures.request(headline: long, locale: "de-DE"))
        let headline = try #require(render.measure.headline)
        #expect(headline.fits)
        #expect((headline.fitScale ?? 1) < 1)
        #expect((headline.fitScale ?? 0) >= ArtworkLayoutEngine.smallestScale)
        #expect(headline.y + headline.height <= 700 + 30, "Inside the 400-high box, give or take the glyphs past a 1.0 line height")
    }

    @Test func textThatCantFitEvenSmallSaysSo() async throws {
        let long = Array(repeating: "Unendlich lange Überschrift", count: 12).joined(separator: " ")
        let render = try await renderer.render(ArtworkWebFixtures.request(headline: long, locale: "de-DE"))
        let headline = try #require(render.measure.headline)
        #expect(!headline.fits)
        #expect(headline.fitScale == ArtworkLayoutEngine.smallestScale)
        #expect(!render.measure.headlineFits)
    }

    @Test func withoutFitTheOverflowIsStillReported() async throws {
        let long = Array(repeating: "Overflowing words", count: 10).joined(separator: " ")
        let render = try await renderer.render(ArtworkWebFixtures.request(ArtworkWebFixtures.searchPage(fit: false), headline: long))
        #expect(render.measure.headline?.fits == false)
        #expect(render.measure.headline?.fitScale == 1)
    }

    /// The page's scripts, inline handlers and network loads never run.
    @Test func thePagesScriptsAndTheNetworkAreKeptOut() async throws {
        let html = ArtworkWebFixtures.searchPage(extraBody: """
        <script>document.querySelector('h1').setAttribute('data-ran', 'yes'); document.title = 'ran';</script>
        <img id="outside" src="https://example.com/pixel.png" onload="document.title='loaded'">
        <div data-al="capture" data-slot="7" style="width:10px;height:10px"></div>
        """)
        let render = try await renderer.render(ArtworkWebFixtures.request(html, headline: "Safe"))
        #expect(render.measure.headline?.text == "Safe", "The script didn't run: the headline is AppLocalizer's")
        let missing = render.measure.elements(.capture).first { $0.slot == 7 }
        #expect(missing != nil)
        #expect(missing?.isLoaded == nil, "Not an image: no load state")
    }

    @Test func rightToLeftLanguagesSetTheDirection() async throws {
        let ltr = try await renderer.measure(ArtworkWebFixtures.request(headline: "Hello"))
        let rtl = try await renderer.measure(ArtworkWebFixtures.request(headline: "مرحبا", locale: "ar-SA", isRightToLeft: true))
        let left = try #require(ltr.elements(.capture).first)
        let right = try #require(rtl.elements(.capture).first)
        #expect(abs(left.x - 2540) < 2)
        #expect(abs(right.x - 400) < 2, "inset-inline-end mirrors with dir=rtl")
    }

    @Test func behindTheTextIsTheBackground() async throws {
        let render = try await renderer.render(ArtworkWebFixtures.request(headline: "WWWWWW"), behindText: true)
        let behind = try #require(render.behindText)
        #expect(behind.width == ArtworkPixels.maximumWidth)
        let headline = try #require(render.measure.headline)
        let center = ArtworkWebFixtures.color(in: behind, x: headline.frame.midX, y: headline.frame.midY)
        #expect(ArtworkWebFixtures.isClose(center, ArtworkWebFixtures.background))
    }

    @Test func motionIsSteppedAndTextThatMovesIsFound() async throws {
        let css = """
        .sun { position: absolute; left: 2000px; top: 200px; width: 200px; height: 200px; background: #ffd27a;
               animation: rise 20s linear infinite; }
        @keyframes rise { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(1000px); } }
        h1 { animation: drift 10s ease-in-out infinite; }
        @keyframes drift { 0%, 100% { transform: translateX(0); } 50% { transform: translateX(300px); } }
        """
        let html = ArtworkWebFixtures.searchPage(extraCSS: css, extraBody: "<div class=\"sun\"></div>")
        let start = try await renderer.render(ArtworkWebFixtures.request(html), checksMotion: true)
        #expect(start.measure.moves)
        #expect(start.moving == [.headline])
        #expect(start.measure.motionsThatMayJump(loopSeconds: 20).isEmpty)
        let yellow = TemplateColor(red: 1, green: 0xD2 / 255, blue: 0x7A / 255)
        #expect(ArtworkWebFixtures.isClose(ArtworkWebFixtures.color(in: start.image, x: 2100, y: 300), yellow))
        let half = try await renderer.render(ArtworkWebFixtures.request(html, time: 10))
        #expect(ArtworkWebFixtures.isClose(ArtworkWebFixtures.color(in: half.image, x: 2100, y: 1300), yellow), "Halfway, the sun is 1000 px lower")
        #expect(ArtworkWebFixtures.isClose(ArtworkWebFixtures.color(in: half.image, x: 2100, y: 300), ArtworkWebFixtures.background))
    }

    @Test func motionThatDoesntDivideTheLoopMayJump() async throws {
        let css = ".x { width: 10px; height: 10px; animation: spin 7s linear infinite; } @keyframes spin { to { transform: rotate(360deg); } }"
        let measure = try await renderer.measure(ArtworkWebFixtures.request(ArtworkWebFixtures.searchPage(extraCSS: css, extraBody: "<div class=\"x\"></div>")))
        #expect(measure.motionsThatMayJump(loopSeconds: 20).count == 1)
    }

    @Test func aPageThatsTooHeavyIsRefused() async throws {
        let html = ArtworkWebFixtures.searchPage(extraBody: "<!--" + String(repeating: "x", count: AutopilotArtworkDesign.maximumBytes) + "-->")
        await #expect(throws: ArtworkWebError.self) {
            _ = try await renderer.render(ArtworkWebFixtures.request(html))
        }
    }

    @Test func aLoopIsWrittenFromThePagesMotion() async throws {
        let css = """
        .sun { position: absolute; left: 0; top: 0; width: 100px; height: 100px; background: #fff; animation: a 20s linear infinite; }
        @keyframes a { to { transform: translateX(3000px); } }
        """
        let html = ArtworkWebFixtures.searchPage(extraCSS: css, extraBody: "<div class=\"sun\"></div>")
        let url = FileManager.default.temporaryDirectory.appending(path: "web-loop-\(UUID().uuidString).mov")
        defer { try? FileManager.default.removeItem(at: url) }
        let facts = try await ArtworkWebLoop.write(ArtworkWebFixtures.request(html, pixelWidth: nil), to: url, frames: 6, renderer: renderer)
        #expect(facts.frames == 6)
        #expect(facts.byteCount > 0)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    /// A page lent out again right after it's given back (a header's loop
    /// right after its still) loads its own page: the empty page the last
    /// render left loading ends cancelled (-999) once the next load starts,
    /// and that isn't the next load's failure.
    @Test func aPageLentAgainAtOnceLoadsItsOwnPage() async throws {
        let page = try await ArtworkWebPage(rules: ArtworkWebBlocking.list())
        defer { page.close() }
        let cleared = try #require(page.webView.loadHTMLString("", baseURL: nil), "The empty page clear() starts")
        let loading = Task { try await page.load(ArtworkWebFixtures.request(kind: .header, pixelWidth: 480), fontCSS: ArtworkWebFonts.css) }
        while !page.isLoading { await Task.yield() }
        page.webView(page.webView, didFail: cleared, withError: URLError(.cancelled))
        let measure = try await loading.value
        #expect(measure.headline != nil)
    }

    @Test func theBundledFontsAreServed() {
        #expect(ArtworkWebFonts.css.contains("font-family: \"Playfair Display\""))
        #expect(ArtworkWebFonts.data(named: "Anton-Regular.ttf")?.isEmpty == false)
        #expect(ArtworkWebFonts.templateName(of: "ui-serif") == "New York")
        #expect(ArtworkWebFonts.templateName(of: "Anton") == "Anton")
    }

    @Test func theLoopKeyFollowsThePage() {
        let first = ArtworkWebLoop.posterKey(poster: "abc", html: "<p>one</p>")
        #expect(first == ArtworkWebLoop.posterKey(poster: "abc", html: "<p>one</p>"))
        #expect(first != ArtworkWebLoop.posterKey(poster: "abc", html: "<p>two</p>"))
    }
}
#endif
