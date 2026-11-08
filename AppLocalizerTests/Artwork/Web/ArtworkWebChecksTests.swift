//
//  ArtworkWebChecksTests.swift
//  AppLocalizerTests
//

#if DEBUG
import CoreGraphics
import Foundation
import Testing
@testable import AppLocalizer

/// Every check on a Claude Design page reads the page as rendered: its text
/// boxes and their contrast against what's really behind them, the
/// captures as the focal point, and the page's own problems (no place for
/// the text, a capture that didn't load, a page past its canvas, text that
/// moves).
@MainActor
@Suite("Checks on Claude Design pages", .serialized)
struct ArtworkWebChecksTests {
    let renderer = ArtworkWebRenderer(width: 1)

    private func checks(
        _ html: String, kind: AutopilotArtworkKind = .search, headline: String = "Gentle daily quotes", captures: [Int: Data]? = nil
    ) async throws -> (render: ArtworkWebRender, checks: [ArtworkCheck]) {
        var request = ArtworkWebFixtures.request(html, headline: headline, kind: kind)
        if let captures { request.captures = captures }
        let render = try await renderer.render(request, behindText: true, checksMotion: true)
        let input = try ArtworkCheckInput(
            kind: kind, locale: #require(StoreLocaleCatalog.locale(code: "en-US")), image: render.image,
            geometry: ArtworkCheckGeometry(web: render, kind: kind), line: headline, page: render.measure
        )
        return await (render, ArtworkChecker().checks(input))
    }

    @Test func theGeometryIsThePageAsRendered() async throws {
        let render = try await renderer.render(ArtworkWebFixtures.request(), behindText: true)
        let geometry = ArtworkCheckGeometry(web: render, kind: .search)
        #expect(geometry.size == CGSize(width: 3840, height: 2560))
        #expect(geometry.headline.map(\.text) == ["Gentle daily quotes"])
        #expect(geometry.appName?.text == "Alba")
        let contrast = try #require(geometry.headline.first?.contrast)
        #expect(contrast > 10, "White on navy, measured against the navy behind it")
        #expect(geometry.interfaceFrames.count == 1)
        #expect(geometry.visibleFocalFrame.map { abs($0.minX - 2540) < 2 } == true, "The capture is the focal point")
        #expect(geometry.labelFrame != nil, "The icon and the name")
        #expect(geometry.headlineFont == "SF Pro Display", "system-ui is SF Pro")
        #expect(geometry.colors.isEmpty == false)
        #expect(geometry.moving.isEmpty)
    }

    @Test func aWellMadePageHasNoPageProblems() async throws {
        let result = try await checks(ArtworkWebFixtures.searchPage())
        #expect(!result.checks.contains { $0.kind == .page })
        #expect(!result.checks.contains { $0.kind == .textContrast })
        #expect(!result.checks.contains { $0.isError })
    }

    @Test func faintTextIsLowContrast() async throws {
        let result = try await checks(ArtworkWebFixtures.searchPage(extraCSS: "h1 { color: #2a3a4a; }"))
        #expect(result.checks.contains { $0.kind == .textContrast })
    }

    @Test func aPageWithoutTheHeadlineIsWarned() async throws {
        let html = ArtworkWebFixtures.searchPage().replacingOccurrences(of: "data-al=\"headline\"", with: "data-x=\"headline\"")
        let result = try await checks(html)
        let page = result.checks.filter { $0.kind == .page }
        #expect(page.contains { $0.text.contains("no data-al=\"headline\"") && !$0.isError })
    }

    /// Bruma's header concepts write their own phrases: every render said
    /// the page had no place for the placement's text.
    @Test func aPageWithItsOwnPhrasesNeedsNoHeadline() async throws {
        let html = ArtworkWebFixtures.searchPage(extraBody: """
        <p data-al="text" style="position: absolute; left: 200px; top: 900px; width: 1600px; margin: 0; \
        font: 600 90px system-ui; color: #ffffff;">Private until you choose</p>
        """).replacingOccurrences(of: "data-al=\"headline\"", with: "data-x=\"headline\"")
        let result = try await checks(html)
        #expect(!result.checks.contains { $0.text.contains("no data-al=\"headline\"") })
    }

    /// No text to show: nothing is missing.
    @Test func aPlacementWithoutTextNeedsNoHeadline() async throws {
        let html = ArtworkWebFixtures.searchPage().replacingOccurrences(of: "data-al=\"headline\"", with: "data-x=\"headline\"")
        let result = try await checks(html, headline: "")
        #expect(!result.checks.contains { $0.text.contains("no data-al=\"headline\"") })
    }

    @Test func aCaptureThatDoesntLoadIsAnError() async throws {
        let result = try await checks(ArtworkWebFixtures.searchPage(), captures: [:])
        let broken = try #require(result.checks.first { $0.kind == .page && $0.isError })
        #expect(broken.text.contains("the capture of screen 1 didn’t load"))
    }

    @Test func aPagePastItsCanvasIsWarned() async throws {
        let wide = ArtworkWebFixtures.searchPage(
            extraCSS: "html, body { overflow: visible; } .past { position: absolute; left: 3700px; top: 10px; width: 600px; height: 40px; }",
            extraBody: "<div class=\"past\"></div>"
        )
        let result = try await checks(wide)
        #expect(result.checks.contains { $0.kind == .page && $0.text.contains("reaches past its 3840 × 2560 canvas") })
    }

    @Test func textThatMovesInALoopIsWarned() async throws {
        let moving = ArtworkWebFixtures.searchPage(extraCSS: """
        h1 { animation: slide 20s linear infinite; }
        @keyframes slide { 0%, 100% { translate: 0 0; } 50% { translate: 300px 0; } }
        """)
        let result = try await checks(moving)
        #expect(result.render.moving == [.headline])
        let loop = try #require(result.checks.first { $0.kind == .loop })
        #expect(loop.text.contains("the headline move in the loop"))
    }
}
#endif
