//
//  GuidedLookRowArtworkTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Testing
@testable import AppLocalizer

/// A look on Choose shows the header and search Claude Design made for it,
/// under its screenshots, unless they're concepts chosen apart or the look
/// has no screenshots (then they're its picture already).
@MainActor
@Suite("Guided Choose · a look's own header and search")
struct GuidedLookRowArtworkTests {
    @Test func aLookWithScreenshotsShowsItsOwnPages() throws {
        let scene = try #require(StudioDebugWebArtwork.scene(for: "st-choose-web-artwork"))
        let run = scene.run
        #expect(run.plan.makesScreenshots)
        #expect(!run.directionArtworkKinds.isEmpty)
        #expect(GuidedLookRow.showsOwnArtwork(run))
    }

    @Test func conceptsAreChosenApart() throws {
        var run = try #require(StudioDebugWebArtwork.scene(for: "st-choose-web-artwork")).run
        run.proposesConcepts = true
        #expect(run.usesConcepts)
        #expect(!GuidedLookRow.showsOwnArtwork(run))
    }

    @Test func withoutScreenshotsThePagesAreTheLooksPicture() {
        let run = StudioDebugWebArtwork.artworkOnly(.choose)
        #expect(!run.plan.makesScreenshots)
        #expect(!GuidedLookRow.showsOwnArtwork(run))
    }
}
#endif
