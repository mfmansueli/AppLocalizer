//
//  ExtrasReviewPlannerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What Review & Push lists of Autopilot's extras: every file not on App
/// Store Connect yet, its checks, what keeps it out of the push, and the
/// Product Page Optimization tests the artwork allows.
@MainActor
@Suite("Extras review plan")
struct ExtrasReviewPlannerTests {
    @Test func everyFileWaitsArtworkFirstPrimaryLanguageFirst() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        #expect(plan.items.count == 7)
        #expect(plan.items.map(\.id) == [
            "header-en-US", "search-en-US", "header-fr-FR", "search-fr-FR", "header-de-DE", "search-de-DE", "iphone-en-US",
        ])
        #expect(plan.items[0].title == "English (U.S.) · Header 21:9")
        #expect(plan.items[0].fileURL == URL(filePath: "/tmp/extras/header-en-US-sum.png"))
        #expect(plan.items[0].fileName == "header-en-US.png")
        #expect(plan.items[0].localizationID == "loc-en-US")
        #expect(plan.items.last?.kindTitle == "iPhone App Preview")
        #expect(plan.countTitle == "6 images and 1 App Preview")
        #expect(plan.pushedCount == 0)
    }

    @Test func anErrorKeepsTheImageOutButAWarningDoesnt() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        let german = try #require(plan.items.first { $0.id == "header-de-DE" })
        #expect(german.isBlocked)
        #expect(german.blockReason == "German header: ‘−50%’ — discounts and percentages aren’t allowed here.")
        #expect(german.pushItem == nil)

        let english = try #require(plan.items.first { $0.id == "search-en-US" })
        #expect(english.warnings == [ExtrasReviewFixtures.contrast])
        #expect(!english.isBlocked)
        #expect(english.pushItem != nil)

        #expect(plan.blocked.map(\.id) == ["header-de-DE"])
        #expect(plan.pushable.count == 6)
    }

    @Test func aLanguageWithoutALocalizationWaits() throws {
        let plan = try #require(ExtrasReviewFixtures.plan(context: ExtrasReviewFixtures.context(missing: ["fr-FR"])))
        let french = try #require(plan.items.first { $0.id == "search-fr-FR" })
        #expect(french.localizationID == nil)
        #expect(french.blockReason == "App Store Connect has no French localization on this version yet.")
    }

    @Test func whatsAlreadyPushedLeaves() throws {
        var extras = ExtrasReviewFixtures.extras()
        extras.pushedChecksums = ["header-en-US": "header-en-US-sum", "search-en-US": "an older render"]
        let plan = try #require(ExtrasReviewFixtures.plan(extras))
        #expect(!plan.items.contains { $0.id == "header-en-US" })
        #expect(plan.items.contains { $0.id == "search-en-US" }, "A new render goes again")
        #expect(plan.pushedCount == 1)
        // The pushed header still counts for a test.
        #expect(plan.artworkKinds == [.header, .search])
    }

    @Test func whatsDiscardedLeavesUntilItsMadeAgain() throws {
        var extras = ExtrasReviewFixtures.extras()
        extras.discardedChecksums = ["iphone-en-US": "preview-sum", "header-en-US": "an older render"]
        let plan = try #require(ExtrasReviewFixtures.plan(extras))
        #expect(!plan.items.contains { $0.id == "iphone-en-US" })
        #expect(plan.items.contains { $0.id == "header-en-US" }, "A new render comes back")
        #expect(plan.discardedCount == 1)
        #expect(plan.pushedCount == 0)
        #expect(plan.discardedTitle == "1 extra discarded: App Store Connect keeps what it has.")
        #expect(plan.countTitle == "6 images")
    }

    /// An App Preview alone, all of it discarded: the plan stays for Undo.
    @Test func everythingDiscardedStillPlansForUndo() throws {
        var extras = ExtrasReviewFixtures.extras(previews: true)
        extras.artwork = []
        extras.discardedChecksums = ["iphone-en-US": "preview-sum"]
        let plan = try #require(ExtrasReviewFixtures.plan(extras))
        #expect(plan.items.isEmpty)
        #expect(!plan.isEmpty)
        #expect(plan.discardedTitle == "1 extra discarded: App Store Connect keeps what it has.")
    }

    @Test func eachKindGoesToItsPlacements() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        let header = try #require(plan.items.first { $0.id == "header-en-US" }?.pushItem)
        #expect(header.kind == .artwork(placementTypes: ["PRODUCT_PAGE_HEADER_ASSET"]))
        #expect(header.referenceName == "Autopilot · en-US · Header 21:9")
        let preview = try #require(plan.items.first { $0.id == "iphone-en-US" }?.pushItem)
        #expect(preview.kind == .appPreview(posterTimeCode: "00:00:05:00"))
        #expect(preview.fileName == "AppPreview-iPhone-en-US.mov")

        let wide = try #require(ExtrasReviewFixtures.plan(ExtrasReviewFixtures.extras(size: .wide, previews: false)))
        #expect(wide.items.first?.pushItem?.kind == .artwork(placementTypes: ["PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"]))
    }

    /// A motion loop pushes the movie, placed like the image, its first
    /// frame the poster; the tile keeps showing the image.
    @Test func aMotionLoopPushesTheMovie() throws {
        var extras = ExtrasReviewFixtures.extras(previews: false)
        let loop = ExtrasArtworkLoop(fileID: "header-en-US-loop", byteCount: 9000, seconds: 20, framesPerSecond: 30, codec: "H.264", isSeamless: true)
        let index = try #require(extras.artwork.firstIndex { $0.id == "header-en-US" })
        extras.artwork[index].loop = loop
        let plan = try #require(ExtrasReviewFixtures.plan(extras))
        let header = try #require(plan.items.first { $0.id == "header-en-US" })
        #expect(header.isMotion)
        #expect(header.fileURL == URL(filePath: "/tmp/extras/header-en-US-sum.png"), "The tile shows the poster")
        #expect(header.loopFileURL == URL(filePath: "/tmp/extras/header-en-US-loop.mov"))
        let item = try #require(header.pushItem)
        #expect(item.kind == .motionArtwork(placementTypes: ["PRODUCT_PAGE_HEADER_ASSET"]))
        #expect(item.kind.media == .video)
        #expect(item.kind.category == "CREATIVE_ASSETS")
        #expect(item.fileName == "header-en-US.mov")
        #expect(item.fileURL == URL(filePath: "/tmp/extras/header-en-US-loop.mov"))
        #expect(item.referenceName == "Autopilot · en-US · Header 21:9 · motion")
        #expect(loop.chipTitle == "0:20 loop")

        let still = try #require(plan.items.first { $0.id == "search-en-US" })
        #expect(!still.isMotion)
        #expect(still.pushItem?.kind == .artwork(placementTypes: ["APP_STORE_SEARCH_RESULTS_ASSET"]))
    }

    @Test func theHeaderAndSearchCanEachBeTested() throws {
        let plan = try #require(ExtrasReviewFixtures.plan())
        #expect(plan.testPlacements == [.header, .searchResults])
        #expect(plan.kind(for: .header) == .header)
        #expect(plan.kind(for: .searchResults) == .search)
        #expect(plan.controlWaits(.header))

        let wide = try #require(ExtrasReviewFixtures.plan(ExtrasReviewFixtures.extras(size: .wide, previews: false)))
        #expect(wide.testPlacements == [.header, .searchResults])
        #expect(wide.kind(for: .searchResults) == .wide)
    }

    @Test func noExtrasNoPlan() {
        var empty = ExtrasReviewFixtures.extras(previews: false)
        empty.artwork = []
        #expect(ExtrasReviewFixtures.plan(empty) == nil)
        #expect(ExtrasReviewFixtures.planner.plan(appID: "app-1", appName: "Lumen", extras: nil, context: ExtrasReviewFixtures.context()) == nil)
    }

    @Test func aLiveVersionHoldsEverythingBack() throws {
        var context = ExtrasReviewFixtures.context()
        context.version = ScreenshotsTestFixtures.liveVersion
        let plan = try #require(ExtrasReviewFixtures.plan(context: context))
        #expect(plan.blockedReason?.contains("1.3") == true)
        #expect(plan.pushable.isEmpty)
        #expect(plan.items.count == 7, "Still listed, to say why")
    }
}
#endif
