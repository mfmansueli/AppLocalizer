//
//  ScreenshotStudioViewerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the Studio opens full size: the product page's App Preview and
/// screenshots, the header and search artwork, a direction's set, one
/// App Preview; and the arrows and close between them.
@MainActor
@Suite("ScreenshotStudioModel · full-size viewer")
struct ScreenshotStudioViewerTests {
    /// The new set, after a run whose extras were saved with it.
    private func newSet(_ run: AutopilotRun) async -> (ScreenshotsViewModel, AutopilotCenter) {
        let center = StudioTestFixtures.center(run)
        var document = ScreenshotsDebugDocuments.standard
        document.extras = StudioDebugExtras.extras(for: run)
        let model = await StudioTestFixtures.screenshots(center: center, document: document)
        model.studio.choice = .new
        return (model, center)
    }

    @Test func aScreenshotOpensAmongItsNeighbours() async throws {
        let (model, _) = await newSet(StudioDebugRuns.run(.ready))
        let studio = model.studio
        let shots = studio.preview.shots
        #expect(shots.count == 5)

        studio.openGallery(at: 1)
        var viewer = try #require(studio.viewer)
        #expect(viewer.items.count == shots.count, "No App Preview in this run")
        #expect(viewer.current.title == shots[1].label)
        #expect(viewer.current.subtitle.hasPrefix("English (U.S.) · iPhone"))
        #expect(viewer.countTitle == "2 of 5")

        studio.stepViewer(1)
        viewer = try #require(studio.viewer)
        #expect(viewer.current.id == "shot.\(shots[2].slot)")
        studio.closeViewer()
        #expect(studio.viewer == nil)
    }

    @Test func theAppPreviewComesFirst() async throws {
        let (model, _) = await newSet(StudioDebugExtras.run(.ready, languages: .primary))
        let studio = model.studio
        let tile = try #require(studio.extrasPreview?.appPreview)

        studio.openGallery(at: 0)
        let viewer = try #require(studio.viewer)
        #expect(viewer.items.count == studio.preview.shots.count + 1)
        #expect(viewer.current.content == .appPreview(tile.file))
        #expect(viewer.current.title == "App Preview")
        #expect(viewer.current.subtitle.contains("♫ Warm acoustic"))
        #expect(viewer.current.subtitle.hasSuffix("click the video to play or pause"))
    }

    @Test func aWatchedAppPreviewSaysItsVersion() async throws {
        var run = StudioDebugExtras.run(.watchPreview, languages: .primary)
        run.previewReview = AutopilotPreviewReview(version: 3)
        let (model, _) = await newSet(run)
        let file = try #require(model.document?.extras?.previews.first)
        model.studio.openPreview(file)
        let viewer = try #require(model.studio.viewer)
        #expect(viewer.current.title == "App Preview · v3")
        #expect(viewer.countTitle == nil)
    }

    @Test func theHeaderAndSearchArtworkOpenTogether() async throws {
        let (model, _) = await newSet(StudioDebugExtras.run(.ready, languages: .primary))
        model.studio.openArtwork(at: 1)
        let viewer = try #require(model.studio.viewer)
        #expect(viewer.items.map(\.id) == ["artwork.header", "artwork.search"])
        #expect(viewer.current.title.hasPrefix("Search results · 3:2"))
        #expect(viewer.items[0].title.hasPrefix("Product page header · 21:9"))
        #expect(viewer.current.subtitle == "English (U.S.) · New set · not pushed")
    }

    /// Board 32: a motion loop opens as its poster, said to be a loop, and
    /// the set's summary says so.
    @Test func aMotionLoopSaysItLoops() async throws {
        let (model, _) = await newSet(StudioDebugArtMotion.ready())
        model.studio.openArtwork(at: 0)
        let viewer = try #require(model.studio.viewer)
        #expect(viewer.current.title.hasPrefix("Product page header · 21:9"))
        #expect(viewer.current.title.hasSuffix(" · motion"))
        #expect(viewer.current.subtitle == "20-second loop · plays muted on repeat · English (U.S.) · New set · not pushed")
        let line = model.studio.summary.lines.first { $0.label == "Header, search" }
        #expect(line?.value.hasPrefix("21:9 and 3:2 · 20 s loops · ") == true)

        let (still, _) = await newSet(StudioDebugArtMotion.ready(motion: .still))
        #expect(still.studio.summary.lines.first { $0.label == "Header, search" }?.value.contains(" · still · ") == true)
    }

    @Test func oneWideImageIsOneItem() async throws {
        let (model, _) = await newSet(StudioDebugExtras.run(.ready, size: .wide, languages: .primary))
        model.studio.openArtwork(at: 0)
        let viewer = try #require(model.studio.viewer)
        #expect(viewer.items.count == 1)
        #expect(viewer.current.title.hasPrefix("Header and search results · 16:9"))
    }

    @Test func aDirectionsSetOpensAtTheScreenClicked() async throws {
        let (model, center) = await newSet(StudioDebugRuns.run(.choose))
        let direction = try #require(center.run(for: StudioTestFixtures.app.id)?.directions[1])
        model.studio.openDirection(direction, at: 2)
        var viewer = try #require(model.studio.viewer)
        #expect(viewer.items.count >= 5)
        #expect(viewer.current.title == "\(direction.name) · 3")
        #expect(viewer.current.subtitle.hasPrefix("Direction from "))

        model.studio.openDirection(direction, at: 0, asNewSet: true)
        viewer = try #require(model.studio.viewer)
        #expect(viewer.current.title == "New screenshot 1 · Today")
        #expect(viewer.current.subtitle.hasSuffix("not pushed"))
    }

    /// In Design and Choose, a direction's header, search and App Preview
    /// poster open full size in its look: the loops play, and the poster
    /// opens the recording the App Preview is cut from.
    @Test func aDirectionsHeaderSearchAndRecordingOpenTogether() async throws {
        let (model, center) = await newSet(StudioDebugArtMotion.revising)
        let direction = try #require(center.run(for: StudioTestFixtures.app.id)?.directions[0])
        model.studio.openDirectionExtras(direction, at: 1)
        var viewer = try #require(model.studio.viewer)
        #expect(Array(viewer.items.map(\.id).prefix(2)) == ["direction.artwork.header", "direction.artwork.search"])
        #expect(viewer.index == 1)
        #expect(viewer.current.title == "Quiet Indigo · Search results · 3:2 · 3840 × 2560 · motion")
        #expect(viewer.current.subtitle == "20-second loop · plays muted on repeat · Direction from Claude Design · English (U.S.)")
        guard case let .artwork(search) = viewer.current.content else {
            Issue.record("The search image opens as artwork")
            return
        }
        #expect(search.template == direction.artworkLook)
        #expect(search.isMotion)
        #expect(viewer.items[0].action == .headerGuide)

        model.studio.openDirectionExtras(direction, at: 2)
        viewer = try #require(model.studio.viewer)
        #expect(viewer.items.count == 3)
        #expect(viewer.current.id.hasPrefix("direction.recording."))
        #expect(viewer.current.title.hasPrefix("Raw recording · "))
        #expect(viewer.current.subtitle.contains("with Quiet Indigo’s captions and end card"))
    }

    @Test func aNoteSaysWhatItCanChange() async {
        let (motion, _) = await newSet(StudioDebugArtMotion.revising)
        let note = motion.studio.revisionScopeNote ?? ""
        #expect(note.hasPrefix("A note changes the screenshots and the header and search images"))
        #expect(note.contains("the motion itself can’t change yet"))

        var still = StudioDebugExtras.run(.choose, languages: .primary)
        still.plan.alsoMakes.setMotion(.still)
        let (stillModel, _) = await newSet(still)
        #expect(stillModel.studio.revisionScopeNote?.contains("motion") == false)

        let (plain, _) = await newSet(StudioDebugRuns.run(.choose))
        #expect(plain.studio.revisionScopeNote == nil)

        // Without screenshots, a note is only about the header and search.
        let (artworkOnly, _) = await newSet(StudioDebugWebArtwork.artworkOnly(.choose))
        let only = artworkOnly.studio.revisionScopeNote ?? ""
        #expect(only.hasPrefix("A note changes the header and search images: colors, type, layout and what they show."))
        #expect(only.contains("The live screenshots stay as they are."))
    }
}
#endif
