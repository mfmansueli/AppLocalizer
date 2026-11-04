//
//  ReviewViewerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review & Push's full-size viewer: a click on a slot's live or new
/// screenshot opens the set's slots on that side, ← → keep the side and
/// Live Now | New switches it; a click on an extra opens its card's
/// languages, where the App Preview and a motion image play.
@MainActor
@Suite("Review & Push viewer")
struct ReviewViewerTests {
    private let queue = ChangeQueue()
    private let primary = "English (U.S.)"

    private func makeViewModel() -> ReviewPushViewModel {
        let push = PushController(queue: queue, history: PushHistory(), transport: FakePushTransport())
        return ReviewPushViewModel(queue: queue, push: push, selectedAppID: ScreenshotPushTestFixtures.app.id, appName: { _ in "Lumen Journal" })
    }

    /// German's set: three live screenshots, slots 1–3 replaced.
    private var group: ScreenshotPlanGroup {
        ScreenshotPushTestFixtures.group(.german, live: ScreenshotPushTestFixtures.liveSet(.german, count: 3), slots: [0, 1, 2])
    }

    // MARK: - Screenshots

    @Test func aNewScreenshotOpensItsSetOnTheNewSide() throws {
        let vm = makeViewModel()
        let group = group
        vm.openScreenshot(group.items[1], in: group, side: .new, primaryLocaleName: primary)
        let viewer = try #require(vm.viewer)
        #expect(viewer.current.id == "shot.\(group.items[1].id)")
        #expect(viewer.current.title == group.items[1].title(localeName: "German"))
        #expect(viewer.list.countTitle == "2 of 3")
        #expect(viewer.shownSide == .new)
        #expect(viewer.subtitle.hasPrefix("New · replaces what’s live"), "\(viewer.subtitle)")
        #expect(viewer.current.comparesSides)
    }

    @Test func aLiveScreenshotOpensOnTheLiveSide() throws {
        let vm = makeViewModel()
        let group = group
        vm.openScreenshot(group.items[0], in: group, side: .live, primaryLocaleName: primary)
        let viewer = try #require(vm.viewer)
        #expect(viewer.shownSide == .live)
        #expect(viewer.subtitle.hasPrefix("Live now on App Store Connect"), "\(viewer.subtitle)")
    }

    @Test func stepsKeepTheSideAndStopAtTheEnds() throws {
        let vm = makeViewModel()
        let group = group
        vm.openScreenshot(group.items[0], in: group, side: .live, primaryLocaleName: primary)
        vm.stepViewer(1)
        vm.stepViewer(1)
        vm.stepViewer(1)
        let viewer = try #require(vm.viewer)
        #expect(viewer.current.id == "shot.\(group.items[2].id)")
        #expect(viewer.shownSide == .live)
        #expect(!viewer.list.hasNext)
    }

    @Test func liveNowAndNewSwitchTheSide() throws {
        let vm = makeViewModel()
        let group = group
        vm.openScreenshot(group.items[0], in: group, side: .new, primaryLocaleName: primary)
        let before = try #require(vm.viewer).contentID
        vm.showViewerSide(.live)
        #expect(vm.viewer?.shownSide == .live)
        #expect(vm.viewer?.contentID != before, "The large image loads again for the other side")
        vm.flipViewerSide()
        #expect(vm.viewer?.shownSide == .new)
    }

    @Test func aSlotWithNothingLiveSaysThePushAddsIt() {
        let group = ScreenshotPushTestFixtures.group(.german, live: ScreenshotPushTestFixtures.liveSet(.german, count: 1), slots: [0, 1])
        let item = ReviewPushViewModel.viewerItem(group.items[1], in: group, primaryLocaleName: primary)
        #expect(item.subtitle(.live) == "Nothing live in this position: the push adds it")
        #expect(item.subtitle.hasPrefix("New · adds a screenshot here"), "\(item.subtitle)")
    }

    @Test func aLanguageWithoutASetSaysWhatItShowsMeanwhile() {
        let group = ScreenshotPushTestFixtures.group(.german, live: nil, slots: [0])
        let item = ReviewPushViewModel.viewerItem(group.items[0], in: group, primaryLocaleName: primary)
        #expect(item.subtitle(.live) == "Nothing live: German shows English (U.S.)’s screenshots until this push")
    }

    @Test func aProposalSaysWhoMadeIt() {
        var group = group
        group.items[0].source = .assistant(client: "Claude Code")
        let item = ReviewPushViewModel.viewerItem(group.items[0], in: group, primaryLocaleName: primary)
        #expect(item.subtitle.hasSuffix("from Claude Code"), "\(item.subtitle)")
    }

    @Test func closingTheViewerClearsIt() {
        let vm = makeViewModel()
        let group = group
        vm.openScreenshot(group.items[0], in: group, side: .new, primaryLocaleName: primary)
        vm.closeViewer()
        #expect(vm.viewer == nil)
    }

    // MARK: - Extras

    @Test func anArtworkOpensItsCardsLanguages() throws {
        let vm = makeViewModel()
        let plan = try #require(ExtrasReviewFixtures.plan())
        let german = try #require(plan.items.first { $0.id == "header-de-DE" })
        vm.openExtra(german, in: plan)
        let viewer = try #require(vm.viewer)
        // The primary language first, then by name.
        #expect(viewer.list.items.map(\.id) == ["extra.header-en-US", "extra.header-fr-FR", "extra.header-de-DE"])
        #expect(viewer.current.title == "German · Header 21:9")
        #expect(viewer.list.countTitle == "3 of 3")
        #expect(viewer.subtitle.hasSuffix("kept out of the push"), "The discount keeps it out: \(viewer.subtitle)")
        #expect(!viewer.current.comparesSides)
        #expect(!viewer.current.content.plays)
    }

    @Test func anArtworkHasOneSide() throws {
        let vm = makeViewModel()
        let plan = try #require(ExtrasReviewFixtures.plan())
        let search = try #require(plan.items.first { $0.id == "search-en-US" })
        vm.openExtra(search, in: plan)
        vm.showViewerSide(.live)
        let viewer = try #require(vm.viewer)
        #expect(viewer.shownSide == .new)
        #expect(viewer.subtitle.contains("“Journal in seconds”"), "\(viewer.subtitle)")
    }

    @Test func aMotionImagePlaysOnRepeat() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        var header = try #require(plan.items.first { $0.id == "header-en-US" })
        header.loopFileURL = ExtrasReviewFixtures.folder.appending(path: "loop.mov")
        let item = ReviewPushViewModel.viewerItem(header, musicTitle: nil)
        #expect(item.content.isMotion)
        #expect(item.content.plays)
        #expect(item.subtitle.contains("loop, plays muted on repeat"), "\(item.subtitle)")
    }

    @Test func anAppPreviewPlaysAsItWasMade() throws {
        let vm = makeViewModel()
        var extras = ExtrasReviewFixtures.extras()
        extras.previewMusic = AutopilotPreviewMusic(track: .warmAcoustic)
        let plan = try #require(ExtrasReviewFixtures.plan(extras))
        let preview = try #require(plan.items.first { $0.artworkKind == nil })
        #expect(preview.preview == extras.previews.first, "The planner keeps the App Preview as it was made")
        #expect(plan.musicTitle == AppPreviewTrack.warmAcoustic.title)

        vm.openExtra(preview, in: plan)
        let viewer = try #require(vm.viewer)
        #expect(viewer.list.items.count == 1, "Only the App Previews' card")
        #expect(viewer.current.content.isAppPreview)
        #expect(viewer.current.content.plays)
        #expect(viewer.subtitle == "886 × 1920 · 0:24 · click the video to play or pause")
        guard case let .appPreview(_, file, musicTitle) = viewer.current.content else { return }
        #expect(file.seconds == 24)
        #expect(musicTitle == AppPreviewTrack.warmAcoustic.title)
    }

    @Test func anAppPreviewFromBeforeReadsItsLengthFromTheMovie() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        var preview = try #require(plan.items.first { $0.artworkKind == nil })
        preview.preview = nil
        let item = ReviewPushViewModel.viewerItem(preview, musicTitle: nil)
        guard case let .appPreview(_, file, _) = item.content else {
            Issue.record("Not an App Preview")
            return
        }
        #expect(file.seconds == 0, "0 makes the player read the movie's length")
        #expect(file.pixelSize == preview.pixelSize)
        #expect(!item.subtitle.contains("0:00"))
    }

    @Test func withoutAppPreviewsThereIsNoMusic() throws {
        let plan = try #require(ExtrasReviewFixtures.plan(ExtrasReviewFixtures.extras(previews: false)))
        #expect(plan.musicTitle == nil)
    }
}
#endif
