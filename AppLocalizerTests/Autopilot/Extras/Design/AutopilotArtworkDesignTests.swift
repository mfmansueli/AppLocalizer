//
//  AutopilotArtworkDesignTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// A direction's header and search pages: one per canvas, a revision laid
/// over what's there, kept with the run, and the screens each page shows.
@MainActor
@Suite("Claude Design's artwork pages")
struct AutopilotArtworkDesignTests {
    @Test func eachCanvasHasItsOwnPage() {
        var design = AutopilotArtworkDesign(pages: [.header: "<p>header</p>", .search: "  "])
        #expect(design.page(for: .header) == "<p>header</p>")
        #expect(design.page(for: .search) == nil, "A blank page is no page")
        #expect(design.missing([.header, .search]) == [.search])
        #expect(!design.isEmpty)
        design.setPage("<p>search</p>", for: .search)
        #expect(design.missing([.header, .search]).isEmpty)
        #expect(AutopilotArtworkDesign().isEmpty)
        #expect(AutopilotArtworkDesign(pages: [.wide: "\n"]).isEmpty)
    }

    @Test func aRevisionIsLaidOverThePagesThere() {
        let current = AutopilotArtworkDesign(pages: [.header: "<p>old header</p>", .search: "<p>old search</p>"])
        let revised = AutopilotArtworkDesign(pages: [.search: "<p>new search</p>"]).laid(over: current)
        #expect(revised.page(for: .header) == "<p>old header</p>")
        #expect(revised.page(for: .search) == "<p>new search</p>")
        #expect(AutopilotArtworkDesign(pages: [.header: "<p>h</p>"]).laid(over: nil).pages == ["header": "<p>h</p>"])
    }

    /// Runs and sets saved before pages decode without them.
    @Test func itIsKeptWithTheDirectionAndOldOnesDecodeWithout() throws {
        var direction = try #require(StudioDebugRuns.run(.choose).directions.first)
        direction.artworkDesign = StudioDebugWebArtwork.quietIndigo
        let data = try JSONEncoder().encode(direction)
        #expect(try JSONDecoder().decode(AutopilotDirection.self, from: data).artworkDesign == StudioDebugWebArtwork.quietIndigo)

        direction.artworkDesign = nil
        let old = try JSONEncoder().encode(direction)
        #expect(String(bytes: old, encoding: .utf8)?.contains("artworkDesign") == false)
        #expect(try JSONDecoder().decode(AutopilotDirection.self, from: old).artworkDesign == nil)
    }

    @Test func aPageShowsTheScreensItsCapturesName() {
        #expect(AutopilotArtworkPages.slots(in: "<img data-al=\"capture\" data-slot=\"3\"><img data-slot='1' data-al=\"capture\">") == [0, 2])
        #expect(AutopilotArtworkPages.slots(in: "<div data-al=\"capture\"></div>") == [0], "No slot is screen 1")
        #expect(AutopilotArtworkPages.slots(in: "<h1 data-al=\"headline\"></h1>").isEmpty)
        #expect(AutopilotArtworkPages.slots(in: "<img data-al=\"capture\" data-slot=\"0\">").isEmpty, "Screens count from 1")
        #expect(AutopilotArtworkPages.slots(in: StudioDebugWebArtwork.dawnPanorama.page(for: .search) ?? "") == [0, 1])
    }

    /// The debug scenes' three directions are three different pages.
    @Test func theSampleDirectionsAreDifferentIdeas() {
        let run = StudioDebugWebArtwork.designed(StudioDebugRuns.run(.choose))
        let headers = Set(run.directions.compactMap { $0.artworkDesign?.page(for: .header) })
        #expect(headers.count == 3)
    }
}
#endif
